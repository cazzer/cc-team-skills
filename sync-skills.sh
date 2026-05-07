#!/bin/bash
set -euo pipefail

# Resolve source: either this script's own repo (submodule use)
# or a fresh shallow clone (standalone use)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -d "$SCRIPT_DIR/skills" ] && [ -d "$SCRIPT_DIR/context" ]; then
  SRC="$SCRIPT_DIR"
else
  SRC=$(mktemp -d)
  trap 'rm -rf "$SRC"' EXIT
  git clone --depth 1 git@github.com:cazzer/cc-team-skills.git "$SRC" 2>/dev/null
fi

# Target: find .claude/skills/ relative to git root
GIT_ROOT=$(git rev-parse --show-toplevel)
SKILLS_DIR="$GIT_ROOT/.claude/skills"
mkdir -p "$SKILLS_DIR"

for skill_dir in "$SRC"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  rm -rf "${SKILLS_DIR:?}/$skill_name"
  cp -r "$skill_dir" "$SKILLS_DIR/$skill_name"
done

rm -rf "${SKILLS_DIR:?}/context"
cp -r "$SRC/context" "$SKILLS_DIR/context"

echo "Synced: $(ls -d "$SKILLS_DIR"/*/SKILL.md 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {} | tr '\n' ' ')"
