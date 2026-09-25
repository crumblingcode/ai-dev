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
  compose.override.yaml   per-machine mounts/working_dir (gitignored, created empty by init-host.sh)
  devcontainer.json       VS Code side only: points at the compose service, lists extensions
  init-host.sh            host-side prep run before every start
templates/
  compose.override.yaml   example override: same-path mount of ~/git/ff3bridge, working_dir
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
- Claude Code home is `~/.claude`, on both sides. The container sets
  `CLAUDE_CONFIG_DIR=/home/vscode/.claude`, which moves `.claude.json` from
  its default `~/.claude.json` into `~/.claude/.claude.json`. That way a
  single directory bind mount of the host's `~/.claude` carries all state:
  login, settings, sessions, per-project memory. The host install must
  match. Once per host, move `~/.claude.json` into `~/.claude/` (if it
  exists) and set `CLAUDE_CONFIG_DIR` in your shell:
  ```sh
  set -Ux CLAUDE_CONFIG_DIR $HOME/.claude                        # fish (universal var)
  echo 'export CLAUDE_CONFIG_DIR="$HOME/.claude"' >> ~/.bashrc   # bash
  ```
  Without that, the host claude doesn't find the moved file. It acts logged
  out and creates a fresh `~/.claude.json`, so the two sides end up with
  separate login/project state. `init-host.sh` warns about a stray
  `~/.claude.json`. The shell variable only covers `claude` started from a
  shell. VS Code's Claude extension on the host needs VS Code launched from
  that shell (`code .`), or the variable set in its environment some other
  way.
- Project repos are mounted at the same absolute path as on the host
  (`${HOME}/git/<repo>`, with `${HOME}` expanded on the host). Claude Code
  keys memory, sessions and `.claude.json` project entries on that path, so
  host and container share them. The container user/home (`vscode`,
  `/home/vscode`) doesn't matter for this. What does break is shared config
  that hard-codes the host home (e.g. `/home/you/...` in hook or MCP
  commands in `settings.json`), so write those as `~/...` or `$HOME/...`.
- `init-host.sh` must stay safe to re-run: it only creates what's missing
  (`~/.claude/`, an empty override) and never overwrites or moves files.
- Anything per-machine (extra repos, `working_dir`) goes in the gitignored
  override, not `compose.yaml`. `templates/compose.override.yaml` is the
  documented starting point.
