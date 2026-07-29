# Developer profile

<!-- Seeded to ~/.claude/CLAUDE.md by bootstrap on first run, then never touched
     again. Personalize freely (language, devices, constraints, style) — this
     file stays on your machine and is never written back to the repo. -->

## Working style
- State the intent in one sentence before a change; summarize with a diff after.
- Small, focused commits; keep unrelated refactors separate.

## Safety
- No writes to prod databases or prod clusters without asking first.
- Ask before hard-to-undo operations: git push, migrations, deploys.
- Never write secrets into files or commits; use environment variable references.

## Behavioral rules (always on)
@~/.claude/rules/karpathy-guidelines.md
@~/.claude/rules/karpathy-scale-pillars.md
@~/.claude/rules/karpathy-ground-reality.md
@~/.claude/rules/repo-docs-first.md
