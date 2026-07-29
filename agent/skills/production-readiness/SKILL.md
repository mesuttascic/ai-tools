---
name: production-readiness
description: Production readiness checklist (idempotency, timeouts, DB pool, backpressure, observability). Use before non-trivial backend/infra changes — new mutation paths, DB access, queues, background jobs, k8s deployments.
---

# Production readiness

**Tier:** if the active repo's `AGENTS.md` defines `project_tier` (`startup` | `enterprise`), use it; otherwise assume `startup`. Enterprise: every item is mandatory. Startup: P0 mandatory; P1/P2 may go to the backlog.

## P0 — every mutation path

- **Idempotency:** the same request/event applied twice yields the same result; unique constraint or explicit idempotency key.
- **Timeout + bounded retry:** no infinite retries; exponential backoff + max attempts.
- **Failure state:** DB/state stays consistent on partial failure; nothing stuck `in_progress` (lease/TTL/terminal failed state).
- **Observability:** correlation/trace id end to end; error logs carry service + request context.

## P1 — data and load

- **DB pool:** `instances × pool_size ≤ max_connections` — compute per DB user/pool.
- **Queries:** no unbounded SELECTs; pagination or LIMIT; batch/join on suspected N+1.
- **Backpressure:** concurrency limits, batch sizes, queues — a burst must not let every instance flood the same resource.
- **Hot path:** minimize synchronous external HTTP; move long I/O to a thread pool / separate worker.

## P2 — verification and scale confidence

- **Success criteria:** "it works" is not enough — at least a smoke test, SQL invariant, or integration check.
- **Load hypothesis:** "what breaks at 100× load?" — name the first bottleneck.
- **Runbook (enterprise):** rollback, stale-data cleanup, on-call path.

## Anti-patterns (reject)

- Unjustified global locks — use a partition key (user_id, session_id, tenant_id).
- Public ingress URLs for service-to-service traffic (use cluster DNS / private network).
- New abstractions for a single use.
- Shipping migrations that never ran on dev + preprod (follow the project's migration rule).

## Agent task

Before a non-trivial change, write a short checklist:
```
P0: [idempotency/timeout/state/obs] — OK / gap
P1: [pool/query/backpressure] — OK / gap
Load break: [first bottleneck]
```

If there is a gap, ask the user or propose a minimal fix plan before implementing.
