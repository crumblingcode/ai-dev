FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Replaces the devcontainer "features" (node, claude-code) so the image builds
# identically under `podman compose` and VS Code — features are only applied
# by the devcontainer CLI, so a plain compose build would silently skip them.
# fish is the user's login shell, so VS Code terminals open in it; `podman exec`
# names its shell explicitly (fish or bash). PATH and the other settings come
# from ENV/compose environment, so both shells see the same tools.
# The CLI conveniences are for interactive use and for Claude Code itself.
# Ubuntu ships fd and bat as fdfind/batcat (name clashes); symlink the
# upstream names into /usr/local/bin. Ubuntu's `yq` package is the Python jq
# wrapper, not mikefarah's Go yq, so the latter comes from its GitHub release.
ARG NODE_MAJOR=22

# The container user is named after the host user (compose passes ${USER}).
# The base image's `vscode` (uid/gid 1000) is renamed rather than replaced,
# so the uid that podman's keep-id maps the host user onto stays the same.
ARG USERNAME=vscode
RUN if [ "$USERNAME" != vscode ]; then \
        groupmod -n "$USERNAME" vscode \
        && usermod -l "$USERNAME" -d "/home/$USERNAME" -m vscode \
        && rm /etc/sudoers.d/vscode \
        && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
        && chmod 440 "/etc/sudoers.d/$USERNAME"; \
    fi

RUN DATE_BASELINE=2026-10-12 \
    export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config fish \
        ripgrep fd-find bat fzf jq tree htop shellcheck unzip eza zoxide neovim \
    && ln -s /usr/bin/fdfind /usr/local/bin/fd \
    && ln -s /usr/bin/batcat /usr/local/bin/bat \
    && curl -fsSL -o /usr/local/bin/yq \
        "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$(dpkg --print-architecture)" \
    && chmod +x /usr/local/bin/yq \
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && rm -rf /var/lib/apt/lists/* \
    && chsh -s /usr/bin/fish "$USERNAME"

USER ${USERNAME}

# Rust toolchain baked into the image so it survives container rebuilds,
# plus cargo-deny (`cargo deny check advisories` in project CI). It's built
# from source, which takes a few minutes but needs no release-asset names.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile default --default-toolchain stable \
    && /home/${USERNAME}/.cargo/bin/cargo install --locked cargo-deny \
    && rm -rf /home/${USERNAME}/.cargo/registry /home/${USERNAME}/.cargo/git

# Claude Code via the native installer, as the user, so everything lives under
# ~/.local and is user-writable: that's what lets it auto-update (a root-owned
# `npm install -g` can't). Updates land in the container's writable layer; a
# recreated container starts from the image's version and catches up again.
# CLAUDE_CONFIG_DIR isn't set at build time, so the installer drops a
# ~/.claude.json here that the running container would never read; remove it.
RUN curl -fsSL https://claude.ai/install.sh | bash \
    && rm -rf /home/${USERNAME}/.claude.json /home/${USERNAME}/.claude
ENV PATH="/home/${USERNAME}/.local/bin:/home/${USERNAME}/.cargo/bin:${PATH}"

# Neovim is the editor (git commit messages etc.). Its config is baked in
# from nvim/init.lua: plugin-free, leader = space, <leader>e opens netrw.
COPY --chown=${USERNAME}:${USERNAME} nvim/init.lua /home/${USERNAME}/.config/nvim/init.lua
ENV EDITOR=nvim VISUAL=nvim

# Pre-create the ~/.claude mount point so it is owned by the user, not root.
# ~/.gitconfig pulls in the host's config (mounted read-only at
# ~/.gitconfig.host) but is itself writable for container-local additions.
RUN mkdir -p /home/${USERNAME}/.claude \
    && printf '[include]\n\tpath = ~/.gitconfig.host\n' > /home/${USERNAME}/.gitconfig
