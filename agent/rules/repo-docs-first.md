---
description: "Read the active repo's AGENTS.md and docs index before non-trivial work; don't guess across repos."
alwaysApply: true
---

# Repo docs first

For non-trivial tasks, identify the **active repo root** (open file, workspace folder name).

## Order

1. `<repo>/AGENTS.md`
2. `<repo>/docs/INDEX.md` (else `docs/README.md` or `docs/agent/repo-guide.md`)
3. The **canonical** docs the index points to — skip archive/planning files
4. The repo's own rule/skill directories (`.cursor/rules/`, `.claude/skills/`)

## Cross-repo

Shared infrastructure rules (network/VPN, MCP, migration patterns, k8s operations) are defined in the project's **infra repo**; read them there. Don't invent domain docs for another repo — if it has no index, ask the user.
