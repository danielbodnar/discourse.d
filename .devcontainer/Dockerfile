FROM nixos/nix:latest

# Install basic tools
RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
    nix-channel --update

# Create non-root user
RUN useradd -m -s /bin/bash vscode && \
    mkdir -p /nix/var/nix/{profiles,gcroots}/per-user/vscode && \
    chown -R vscode:vscode /nix/var/nix/{profiles,gcroots}/per-user/vscode

# Setup nix configuration
COPY ./.devcontainer/nix.conf /etc/nix/nix.conf

# Copy flake files
COPY flake.nix flake.lock /workspace/

WORKDIR /workspace

# Allow nix flakes
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf

# Switch to non-root user
USER vscode
