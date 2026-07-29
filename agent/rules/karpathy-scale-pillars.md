---
description: "Karpathy §5: scalability, long-term, efficiency — required for non-trivial architectural decisions."
alwaysApply: true
---

# Karpathy §5 — Scale, long-term, efficiency

"That would take weeks" estimates are usually wrong now. Before taking a shortcut, name the three pillars; if you can't name them, don't decide.

## Three pillars (every architectural decision)

| Pillar | Question |
|--------|----------|
| **Scalability** | What breaks at 100× load / data / users? Name the first bottleneck. |
| **Long term** | Foundation or debt in 6 months? What does it cost to maintain — and to undo? |
| **Efficiency** | Is this the leanest *correct* path? Does the host/platform/repo already provide a primitive? |

**Never trade these away:** security, correctness, error handling that prevents data loss, accessibility, anything the user explicitly asked for.

## Shortcut alarm

Stop if you catch yourself thinking:
- "The right way takes too long — hack/stub/defer for now"
- "No time to validate/secure/migrate"
- "Shortcut for now; we'll fix it later"

If it genuinely takes days, **say so explicitly** — don't silently lower quality.

If a shortcut is unavoidable, mark it inline:
```
// shortcut: global lock; per-account locks if throughput matters
```

## Project pillars

If the project defines extra pillars (portability, privacy, offline-first, …) in its `AGENTS.md` / vision doc, **extend** the three — don't replace them.

**Source:** [clawnify/andrej-karpathy-skills](https://github.com/clawnify/andrej-karpathy-skills) §5.
