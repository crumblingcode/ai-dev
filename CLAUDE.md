# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`ai-dev`: a generic dev container for working on other repos with Claude
Code. It contains no project code. Project repos (e.g. `ff3bridge`) live in
their own git repos on the host and are bind-mounted in through a
per-machine compose override.

## Layout

```
.devcontainer/
  Dockerfile              image: base ubuntu + build tools, Node.js, Claude Code CLI, Rust
  compose.yaml            the container definition (single source of truth)
  compose.override.yaml   per-machine mounts/working_dir (gitignored, created by init-host.sh)
  devcontainer.json       VS Code side only: points at the compose service, lists extensions
  init-host.sh            host-side prep run before every start
templates/
  compose.override.yaml   example override: mount ~/git/ff3bridge, set working_dir
```

## Starting the container

Either way attaches to the same container (fixed compose project name
`ai-dev`, service `dev`, container name `ai-dev`):

```sh
sh .devcontainer/init-host.sh && podman compose \
  -f .devcontainer/compose.yaml -f .devcontainer/compose.override.yaml up -d
podman exec -it ai-dev bash
```

or VS Code's "Reopen in Container" (`initializeCommand` runs `init-host.sh`).
Both must pass the same compose files, or compose sees a config change and
recreates the container.

## Things to know before changing this

- `devcontainer.json` uses `overrideCommand: false`,
  `updateRemoteUserUID: false` and `shutdownAction: none` so a VS
  Code-started container is identical to a compose-started one and isn't
  stopped when VS Code closes.
- Tooling is baked into the Dockerfile, not devcontainer features, because
  plain compose builds would skip features: `build-essential`,
  `pkg-config`, Node.js 22, Claude Code CLI, Rust stable via `rustup` in
  `/home/vscode/.cargo`.
- Runs as `vscode` (uid/gid 1000, podman `keep-id` userns), so files in
  bind mounts are owned by the host user. Every bind mount uses `:z` for
  SELinux (Fedora host).
- Claude Code config is the host's own: `~/.claude` and `~/.claude.json`
  are bind-mounted to the default locations under `/home/vscode`, with no
  `CLAUDE_CONFIG_DIR`. Host and container therefore share login, settings
  and sessions. Per-project memory is keyed on the absolute project path,
  so `/workspaces/ff3bridge` in the container and `~/git/ff3bridge` on the
  host are separate projects to Claude.
- `init-host.sh` must stay safe to re-run: it only creates what's missing
  (`~/.claude/`, `~/.claude.json` as `{}`, an empty override) and never
  overwrites.
- Anything per-machine (extra repos, `working_dir`) goes in the gitignored
  override, not `compose.yaml`. `templates/compose.override.yaml` is the
  documented starting point.
