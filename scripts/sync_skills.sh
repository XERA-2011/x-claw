#!/usr/bin/env bash
set -euo pipefail

SRC_DIR="/Users/xera/GitHub/x-claw/skills"
DEST_DIR="/Users/xera/.openclaw/skills"

mkdir -p "$DEST_DIR"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "Source skills directory not found: $SRC_DIR" >&2
  exit 1
fi

# Sync each skill by name (copy, not symlink).
for skill in "$SRC_DIR"/*; do
  [[ -d "$skill" ]] || continue
  name="$(basename "$skill")"
  rm -rf "$DEST_DIR/$name"
  cp -R "$skill" "$DEST_DIR/$name"
done

echo "Synced skills to $DEST_DIR"
