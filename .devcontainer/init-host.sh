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
if [ -f "$HOME/.claude.json" ]; then
  if [ -e "$HOME/.claude/.claude.json" ]; then
    echo "init-host: both ~/.claude.json and ~/.claude/.claude.json exist." >&2
    echo "  The host claude probably ran without CLAUDE_CONFIG_DIR and made a new" >&2
    echo "  ~/.claude.json. The container uses ~/.claude/.claude.json; remove or" >&2
    echo "  merge the stray one." >&2
  else
    echo "init-host: found ~/.claude.json but no ~/.claude/.claude.json." >&2
    echo "  To share login/project state with the container: mv ~/.claude.json ~/.claude/" >&2
  fi
  echo "  Set CLAUDE_CONFIG_DIR=\$HOME/.claude on the host (see CLAUDE.md)." >&2
fi

# Host git config, mounted read-only. An empty file if there's none yet (git
# also reads ~/.config/git/config, which isn't mounted).
[ -e "$HOME/.gitconfig" ] || : > "$HOME/.gitconfig"

# compose.yaml mounts this repo at ~/git/ai-dev in the container. If the clone
# lives elsewhere it still works, but Claude Code state for it isn't shared.
repo=$(cd "$dir/.." && pwd -P)
expected=$(cd "$HOME/git/ai-dev" 2>/dev/null && pwd -P || true)
if [ "$repo" != "$expected" ]; then
  echo "init-host: this repo is at $repo, not ~/git/ai-dev; its Claude Code" >&2
  echo "  state won't be shared between host and container." >&2
fi

# Per-machine override; an empty one if the user hasn't created theirs yet.
[ -f "$dir/compose.override.yaml" ] || cat > "$dir/compose.override.yaml" <<'YAML'
# Local, untracked extra mounts. See templates/compose.override.yaml.
services:
  dev: {}
YAML
