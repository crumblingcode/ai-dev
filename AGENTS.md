# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

`ai-dev`: a generic dev container for working on other repos with Claude
Code. It contains no project code. Project repos live in their own git
repos on the host and are bind-mounted in through a per-machine compose
override.

## Layout

```
.devcontainer/
  Dockerfile              image: base ubuntu + build tools, Node.js, Claude Code CLI, Rust
  compose.yaml            the container definition (single source of truth)
  compose.override.yaml   per-machine mounts/working_dir (gitignored, created empty by init-host.sh)
  devcontainer.json       VS Code side only (soft-deprecated): points at the compose service, lists extensions
  init-host.sh            host-side prep run before every start
templates/
  compose.override.yaml   example override: same-path mount of ~/git/<repo>, working_dir
```

## Starting the container

Start it with `podman compose` (fixed compose project name `ai-dev`,
service `dev`, container name `ai-dev`). This is the supported way:

```sh
sh .devcontainer/init-host.sh && podman compose \
  -f .devcontainer/compose.yaml -f .devcontainer/compose.override.yaml up -d
podman exec -it ai-dev fish   # or bash
```

The VS Code dev container route ("Reopen in Container", driven by
`devcontainer.json`) is soft-deprecated in favor of the above. It still
works and attaches to the same container (`initializeCommand` runs
`init-host.sh`), but new work should target the compose flow: don't add
anything that only works through `devcontainer.json`, and when the two
conflict, compose wins. Both must pass the same compose files, or compose
sees a config change and recreates the container.

## Things to know before changing this

- `devcontainer.json` uses `overrideCommand: false`,
  `updateRemoteUserUID: false` and `shutdownAction: none` so a VS
  Code-started container is identical to a compose-started one and isn't
  stopped when VS Code closes.
- Tooling is baked into the Dockerfile, not devcontainer features, because
  plain compose builds would skip features: `build-essential`,
  `pkg-config`, fish (vscode's login shell), CLI conveniences (`ripgrep`,
  `fd`, `bat`, `fzf`, `jq`, `yq`, `tree`, `htop`, `shellcheck`, `unzip`,
  `eza`, `zoxide`; no aliases or shell hooks), Node.js 22, Claude Code CLI,
  Rust stable via `rustup` in `/home/vscode/.cargo`.
- Claude Code is installed with the native installer as `vscode`
  (`~/.local/bin/claude`, versions in `~/.local/share/claude`), not
  `npm install -g` as root, so it can auto-update. Updates live in the
  container's writable layer: a recreated container starts from the image's
  version and updates again. Bump `DATE_BASELINE` in the Dockerfile to bust
  the build cache and bake in current versions of everything.
- Tool paths go in the Dockerfile's `ENV PATH`, not shell rc files, so
  bash, fish and non-interactive `podman exec` all see them. No host fish
  config is mounted; the container's fish starts with defaults.
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
- Repos, this one included, are mounted at the same absolute path as on
  the host (`${HOME}/git/<repo>`, with `${HOME}` expanded on the host).
  `ai-dev` itself is assumed to be cloned at `~/git/ai-dev`; `init-host.sh`
  warns if it isn't, and `workspaceFolder` in `devcontainer.json` must match
  the mount target. Claude Code
  keys memory, sessions and `.claude.json` project entries on that path, so
  host and container share them. The container user/home (`vscode`,
  `/home/vscode`) doesn't matter for this. What does break is shared config
  that hard-codes the host home (e.g. `/home/you/...` in hook or MCP
  commands in `settings.json`), so write those as `~/...` or `$HOME/...`.
- The host's `~/.gitconfig` is mounted read-only at `~/.gitconfig.host`.
  The image's own `~/.gitconfig` just `[include]`s it, so it stays writable:
  VS Code adds its credential helper there, and since the file exists VS
  Code doesn't copy the host one over it. Git identity works from plain
  `podman exec` shells too, but push credentials and the SSH agent are
  still only forwarded while VS Code is attached. Host config that
  hard-codes host paths (e.g. `/home/you/.ssh/...` signing keys) won't
  resolve in the container. A single-file mount pins the inode, so after
  editing the host file (editors often replace it) recreate the container.
- `init-host.sh` must stay safe to re-run: it only creates what's missing
  (`~/.claude/`, an empty `~/.gitconfig`, an empty override) and never
  overwrites or moves files.
- Anything per-machine (extra repos, `working_dir`) goes in the gitignored
  override, not `compose.yaml`. `templates/compose.override.yaml` is the
  documented starting point.
