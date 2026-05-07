#!/bin/bash
set -euo pipefail

REPO="git@github.com:cazzer/cc-team-skills.git"
SKILLS_DIR=".claude/skills"
TMP_DIR=$(mktemp -d)

trap 'rm -rf "$TMP_DIR"' EXIT

git clone --depth 1 "$REPO" "$TMP_DIR" 2>/dev/null

mkdir -p "$SKILLS_DIR"

for skill_dir in "$TMP_DIR"/skills/*/; do
  skill_name=$(basename "$skill_dir")
  rm -rf "${SKILLS_DIR:?}/$skill_name"
  cp -r "$skill_dir" "$SKILLS_DIR/$skill_name"
done

rm -rf "${SKILLS_DIR:?}/context"
cp -r "$TMP_DIR/context" "$SKILLS_DIR/context"

echo "Synced skills: $(ls -d "$SKILLS_DIR"/*/SKILL.md 2>/dev/null | xargs -I{} dirname {} | xargs -I{} basename {} | tr '\n' ' ')"
