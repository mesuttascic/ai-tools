---
description: "Karpathy §7: verify against primary sources and the actual codebase — read, don't recall."
alwaysApply: true
---

# Karpathy §7 — Ground in reality, don't recall

Training data is stale and lossy. Check the real source before speaking with confidence.

## Rules

### Facts (APIs, versions, schemas, config)
- Primary sources first: official docs, source code, release notes, vendor pages.
- Blog/forum/SEO content is secondary; on conflict, primary wins.
- Don't present remembered specifics as facts.

### Design / infra decisions
- Read prior art: how have similar systems solved this (postmortems, case studies)?
- Then decide for **this** system.

### This codebase
- Before editing: read the code you touch, its types, its tests; trace the flow end to end.
- **How it works here** beats how it works in general.

### Reuse before build
Before adding new state (config key, column, env var, endpoint, abstraction):
1. Does a framework/platform/library primitive already exist?
2. Does the same pattern exist elsewhere in the monorepo?
3. Don't reinvent what the host already exposes.

### Map before move
For non-trivial work, map first: where does it live, who calls it, which DB/queue/cache boundaries does it cross?

### When you can't verify
Mark it as an assumption + write how to confirm it. Don't turn a guess into a claim.

**Source:** [clawnify/andrej-karpathy-skills](https://github.com/clawnify/andrej-karpathy-skills) §7.
