#!/bin/sh
# Runs on the host before the container starts (VS Code initializeCommand, or
# by hand before `podman compose up`). Makes sure every bind-mount source in
# compose.yaml exists: podman refuses missing sources, and docker would
# create a directory where ~/.claude.json should be a file.
set -eu
dir=$(dirname "$0")

# Host Claude Code config, shared with the container.
mkdir -p "$HOME/.claude"
[ -e "$HOME/.claude.json" ] || echo '{}' > "$HOME/.claude.json"

# Per-machine override; an empty one if the user hasn't created theirs yet.
[ -f "$dir/compose.override.yaml" ] || cat > "$dir/compose.override.yaml" <<'YAML'
# Local, untracked extra mounts. See templates/compose.override.yaml.
services:
  dev: {}
YAML
