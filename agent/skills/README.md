# Skills

Each skill is a folder with a `SKILL.md` (frontmatter: `name` + `description`;
body: instructions). This directory is symlinked to `~/.claude/skills`, so both
Claude Code (native) and Cursor (compatibility path) load every skill here on
all devices.

Project-specific skills do NOT belong here — put them in the project repo's
`.claude/skills/` instead.
