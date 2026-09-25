#!/bin/sh
# Runs on the host before the container starts (VS Code initializeCommand, or
# by hand before `podman compose up`). Makes sure every bind-mount source in
# compose.yaml exists, since podman refuses missing sources. Only creates
# what's missing; never overwrites.
set -eu
dir=$(dirname "$0")

# Host Claude Code config, shared with the container. The container sets
# CLAUDE_CONFIG_DIR=~/.claude, so .claude.json lives in there, not in ~.
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude.json" ] && [ ! -e "$HOME/.claude/.claude.json" ]; then
  echo "init-host: found ~/.claude.json but no ~/.claude/.claude.json." >&2
  echo "  To share login/project state with the container:" >&2
  echo "  mv ~/.claude.json ~/.claude/ && export CLAUDE_CONFIG_DIR=\"\$HOME/.claude\" (in your shell rc)" >&2
fi

# Per-machine override; an empty one if the user hasn't created theirs yet.
[ -f "$dir/compose.override.yaml" ] || cat > "$dir/compose.override.yaml" <<'YAML'
# Local, untracked extra mounts. See templates/compose.override.yaml.
services:
  dev: {}
YAML
