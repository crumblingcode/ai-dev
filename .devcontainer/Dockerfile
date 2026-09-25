FROM mcr.microsoft.com/devcontainers/base:ubuntu

# Replaces the devcontainer "features" (node, claude-code) so the image builds
# identically under `podman compose` and VS Code — features are only applied
# by the devcontainer CLI, so a plain compose build would silently skip them.
ARG NODE_MAJOR=22
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config \
    && curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g @anthropic-ai/claude-code \
    && rm -rf /var/lib/apt/lists/*

USER vscode

# Rust toolchain baked into the image so it survives container rebuilds.
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
    | sh -s -- -y --profile default --default-toolchain stable
ENV PATH="/home/vscode/.cargo/bin:${PATH}"

# Pre-create the ~/.claude mount point so it is owned by vscode, not root.
RUN mkdir -p /home/vscode/.claude
