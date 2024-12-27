# DevContainer Configuration Documentation

## Overview
Development container configuration for Discourse, providing a consistent development environment using VS Code Remote Containers or GitHub Codespaces.

## Directory Structure
```plaintext
.devcontainer/
├── Dockerfile
├── devcontainer.json
├── scripts/
│   ├── post-create.sh
│   └── post-start.sh
├── config/
│   ├── bashrc
│   └── vscode-settings.json
└── nix/
    └── configuration.nix
```

## Configuration Files

### 1. Main Configuration
```jsonc
// devcontainer.json
{
  "name": "Discourse Development",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes"
    },
    "ghcr.io/devcontainers/features/docker-in-docker:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/vscode/.gitconfig,type=bind"
  ],
  "remoteUser": "vscode",
  "settings": {
    "terminal.integrated.defaultProfile.linux": "bash",
    "ruby.useBundler": true,
    "ruby.useLanguageServer": true,
    "ruby.format": "rubocop",
    "editor.formatOnSave": true
  },
  "extensions": [
    "rebornix.ruby",
    "castwide.solargraph",
    "eamodio.gitlens",
    "github.vscode-pull-request-github",
    "jnoortheen.nix-ide",
    "ms-azuretools.vscode-docker"
  ],
  "forwardPorts": [3000, 5432, 6379],
  "postCreateCommand": ".devcontainer/scripts/post-create.sh",
  "postStartCommand": ".devcontainer/scripts/post-start.sh"
}
```

### 2. Dockerfile
```dockerfile
# Dockerfile
FROM nixos/nix:latest

# Install basic tools
RUN nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs && \
    nix-channel --update

# Create non-root user
RUN useradd -m -s /bin/bash vscode && \
    mkdir -p /nix/var/nix/{profiles,gcroots}/per-user/vscode && \
    chown -R vscode:vscode /nix/var/nix/{profiles,gcroots}/per-user/vscode

# Copy configuration files
COPY .devcontainer/config/bashrc /home/vscode/.bashrc
COPY .devcontainer/nix/configuration.nix /etc/nixos/configuration.nix

# Setup development environment
COPY flake.nix flake.lock /workspace/
WORKDIR /workspace

USER vscode
```

### 3. Post-Create Script
```bash
#!/usr/bin/env bash
# post-create.sh

set -euo pipefail

# Initialize development environment
nix develop

# Install Ruby dependencies
bundle install

# Install Node.js dependencies
yarn install

# Setup development database
bundle exec rake db:setup

# Install development tools
gem install solargraph rubocop

# Configure Git
git config --global pull.rebase true
```

### 4. Post-Start Script
```bash
#!/usr/bin/env bash
# post-start.sh

set -euo pipefail

# Start PostgreSQL
pg_ctl start

# Start Redis
redis-server --daemonize yes

# Start background services
bundle exec sidekiq &
```

## VS Code Settings

### 1. Editor Configuration
```jsonc
// .vscode/settings.json
{
  "editor.formatOnSave": true,
  "editor.rulers": [80, 120],
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,

  // Ruby configuration
  "ruby.useBundler": true,
  "ruby.useLanguageServer": true,
  "ruby.lint": {
    "rubocop": true
  },
  "ruby.format": "rubocop",

  // Git configuration
  "git.enableSmartCommit": true,
  "git.autofetch": true,

  // Terminal configuration
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "bash",
      "icon": "terminal-bash"
    }
  }
}
```

### 2. Launch Configuration
```jsonc
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Rails Server",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/rails",
      "args": ["server"]
    },
    {
      "name": "RSpec - Current File",
      "type": "Ruby",
      "request": "launch",
      "program": "${workspaceRoot}/bin/rspec",
      "args": ["${file}"]
    }
  ]
}
```

## Usage

### 1. Basic Usage
```bash
# Open in VS Code
code discourse-project
# Press F1 -> "Remote-Containers: Open Folder in Container"
```

### 2. GitHub Codespaces
```bash
# Open in GitHub Codespaces
gh codespace create
```

### 3. Custom Commands
```bash
# Start development server
./bin/dev

# Run tests
./bin/test

# Open console
./bin/console
```

## Features

### 1. Development Tools
- Ruby with rbenv
- Node.js and Yarn
- PostgreSQL
- Redis
- Git
- Docker
- VS Code extensions

### 2. Database Management
- Automatic database setup
- Migration tools
- Seed data loading

### 3. Testing Tools
- RSpec
- Rubocop
- Solargraph
- Database cleaner

## Customization

### 1. Adding New Dependencies
```nix
# flake.nix
{
  devShell = {
    packages = with pkgs; [
      # Add new packages here
      postgresql_15
      redis
    ];
  };
}
```

### 2. Custom Scripts
```bash
# .devcontainer/scripts/custom.sh
#!/usr/bin/env bash

# Add custom initialization logic
```

### 3. Environment Variables
```bash
# .devcontainer/config/env
export DISCOURSE_DEV_DB_USERNAME="discourse"
export DISCOURSE_DEV_DB_PASSWORD="discourse"
```

## Troubleshooting

### Common Issues

1. Container Build Failures
```bash
# Rebuild container
Remote-Containers: Rebuild Container
```

2. Database Connection Issues
```bash
# Check PostgreSQL status
pg_ctl status
# Start PostgreSQL if needed
pg_ctl start
```

3. Permission Issues
```bash
# Fix permissions
sudo chown -R vscode:vscode /workspace
```

## Best Practices

### 1. Version Control
```gitignore
# .gitignore
.devcontainer/config/env
.devcontainer/data/
```

### 2. Security
```bash
# Use HTTPS for git
git config --global url."https://".insteadOf git://
```

### 3. Performance
```jsonc
// devcontainer.json
{
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
}
```

## Contributing
1. Fork repository
2. Create feature branch
3. Make changes
4. Test changes
5. Submit pull request

## License
MIT License
