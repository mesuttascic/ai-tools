# ai-tools

A portable, tool-agnostic agent configuration layer: one canonical set of
behavioral rules and skills that follows you across devices and works with
Claude Code, Cursor, and any agent that reads the same formats.

```
agent/
  rules/       always-on behavioral rules (markdown, Cursor-compatible frontmatter)
  skills/      on-demand skills (Agent Skills format: SKILL.md per folder)
  templates/   starting points for your personal ~/.claude files
bootstrap.sh   setup for macOS / Linux
bootstrap.ps1  setup for Windows
```

Two kinds of content, two mechanisms:

- **Shared** (`rules/`, `skills/`) — symlinked into `~/.claude`; updates arrive
  with `git pull` on every device.
- **Personal** (`CLAUDE.md` profile, `settings.json`) — seeded from
  `templates/` on first run, then yours: edited locally, never written back to
  this repo.

## Setup

```bash
# macOS / Linux
git clone https://github.com/mesuttascic/ai-tools ~/ws/ai-tools && ~/ws/ai-tools/bootstrap.sh
```

```powershell
# Windows (Developer Mode required for symlinks)
git clone https://github.com/mesuttascic/ai-tools $env:USERPROFILE\ws\ai-tools
& "$env:USERPROFILE\ws\ai-tools\bootstrap.ps1"
```

## How tools pick it up

| Tool | Mechanism |
|------|-----------|
| Claude Code | reads `~/.claude` natively: profile imports the rules, skills load on demand |
| Cursor | loads the same skills via its `~/.claude/skills` compatibility path; for the rules, paste your `~/.claude/CLAUDE.md` once into Settings > Rules |
| Others | anything that understands `SKILL.md` or plain markdown rules can point at `agent/` |

## Scope

This is the **personal** layer only. Project- and company-specific content —
business rules, MCP servers, network details, credentials — belongs in each
project's own repo (`AGENTS.md`, `.mcp.json`), never here. No secrets,
anywhere, ever.

## Credits

Karpathy behavioral rules adapted from
[multica-ai/andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)
and the [clawnify fork](https://github.com/clawnify/andrej-karpathy-skills) (§5–§7).
