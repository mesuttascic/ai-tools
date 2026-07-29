#!/usr/bin/env bash
# Links shared rules/skills into ~/.claude and seeds personal files from
# agent/templates on first run. Idempotent — safe to re-run.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
mkdir -p "$CLAUDE_DIR"

link() {
  local src="$1" dst="$2"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%s)"
    echo "backed up: $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "link:   $dst -> $src"
}

seed() {
  local src="$1" dst="$2"
  [ -L "$dst" ] && [ ! -e "$dst" ] && rm "$dst"  # dangling link from an old layout
  if [ -e "$dst" ]; then
    echo "kept:   $dst (personal, not touched)"
  else
    cp "$src" "$dst"
    echo "seeded: $dst (edit freely — stays local)"
  fi
}

link "$REPO/agent/rules"  "$CLAUDE_DIR/rules"
link "$REPO/agent/skills" "$CLAUDE_DIR/skills"
seed "$REPO/agent/templates/CLAUDE.md"     "$CLAUDE_DIR/CLAUDE.md"
seed "$REPO/agent/templates/settings.json" "$CLAUDE_DIR/settings.json"

echo
echo "Done. Claude Code reads ~/.claude natively; Cursor picks up the same"
echo "skills via its ~/.claude/skills compatibility path. For Cursor rules,"
echo "paste your ~/.claude/CLAUDE.md once into Cursor > Settings > Rules."
