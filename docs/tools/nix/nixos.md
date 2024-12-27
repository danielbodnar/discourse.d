# Nix & NixOS Discourse Configuration Documentation

## Overview
Complete Nix-based development environment and NixOS configuration for Discourse, providing reproducible builds, development environments, and production deployments.

## Table of Contents
1. [Development Environment](#development-environment)
2. [NixOS Configuration](#nixos-configuration)
3. [DevContainer Setup](#devcontainer-setup)
4. [Deployment](#deployment)
5. [Testing](#testing)

## Development Environment

### Flake Structure
```plaintext
.
├── flake.nix
├── flake.lock
├── devShell.nix
├── packages/
│   └── discourse/
│       ├── default.nix
│       └── gemset.nix
└── modules/
    └── discourse/
        └── default.nix
```

### Flake Configuration
```nix
# flake.nix
{
  description = "Discourse Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, flake-utils, devenv, ... }: {
    # Output definitions
  };
}
```

### Development Shell
```nix
# devShell.nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    ruby_3_2
    nodejs_18
    yarn
    postgresql_15
    redis
    # Additional dependencies
  ];

  shellHook = ''
    export DISCOURSE_DEV_DB_USERNAME="discourse"
    export DISCOURSE_DEV_DB_PASSWORD="discourse"
    # Additional environment setup
  '';
}
```

## NixOS Configuration

### System Configuration
```nix
# configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./discourse.nix
  ];

  # System configuration
  boot.loader.systemd-boot.enable = true;
  networking.hostName = "discourse";

  # Service configuration
  services.discourse = {
    enable = true;
    hostname = "discourse.example.com";
    # Additional configuration
  };
}
```

### Discourse Service Module
```nix
# modules/discourse/default.nix
{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.discourse;
in {
  options.services.discourse = {
    enable = mkEnableOption "Discourse forum";

    hostname = mkOption {
      type = types.str;
      description = "Hostname for Discourse";
    };

    # Additional options
  };

  config = mkIf cfg.enable {
    # Service implementation
  };
}
```

## Usage Examples

### Development Environment
```bash
# Enter development shell
nix develop

# Or with direnv
echo "use flake" > .envrc
direnv allow
```

### System Deployment
```bash
# Build NixOS configuration
nixos-rebuild switch --flake .#discourse

# Test configuration
nixos-rebuild test --flake .#discourse
```

### Package Building
```bash
# Build Discourse package
nix build .#discourse

# Enter development shell
nix develop .#discourse
```

## Development Workflow

### 1. Environment Setup
```bash
# Clone repository
git clone https://github.com/your/discourse-nix.git
cd discourse-nix

# Enter development shell
nix develop
```

### 2. Local Development
```bash
# Start PostgreSQL
pg_ctl start

# Start Redis
redis-server &

# Start Discourse
bundle exec rails server
```

### 3. Testing
```bash
# Run tests
bundle exec rspec

# Run specific tests
bundle exec rspec spec/models/user_spec.rb
```

## Production Deployment

### 1. System Configuration
```nix
# discourse-production.nix
{
  services.discourse = {
    enable = true;
    hostname = "discourse.production.com";
    ssl = {
      enable = true;
      email = "admin@example.com";
    };
    smtp = {
      enable = true;
      server = "smtp.example.com";
      # Additional SMTP configuration
    };
  };
}
```

### 2. Deployment Steps
```bash
# Build and activate configuration
sudo nixos-rebuild switch \
  --flake .#discourse-production

# Verify deployment
systemctl status discourse
```

## Backup and Restore

### 1. Backup Configuration
```nix
{
  services.discourse.backup = {
    enable = true;
    frequency = "daily";
    retention = 7;
    s3 = {
      enable = true;
      bucket = "discourse-backups";
      # Additional S3 configuration
    };
  };
}
```

### 2. Backup Commands
```bash
# Manual backup
discourse-backup create

# List backups
discourse-backup list

# Restore backup
discourse-backup restore latest
```

## Monitoring and Logging

### 1. Prometheus Integration
```nix
{
  services.discourse.monitoring = {
    enable = true;
    prometheus = {
      enable = true;
      port = 9394;
    };
  };
}
```

### 2. Logging Configuration
```nix
{
  services.discourse.logging = {
    level = "info";
    json = true;
    destination = "journald";
  };
}
```

## Security Considerations

### 1. SSL Configuration
```nix
{
  services.discourse.ssl = {
    enable = true;
    provider = "letsencrypt";
    email = "admin@example.com";
    extraDomains = [ "forum.example.com" ];
  };
}
```

### 2. Firewall Rules
```nix
{
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
    extraRules = ''
      # Additional firewall rules
    '';
  };
}
```

## Troubleshooting

### Common Issues

1. Database Connection
```bash
# Check PostgreSQL status
systemctl status postgresql

# Verify connection
psql -U discourse -d discourse_production
```

2. Redis Connection
```bash
# Check Redis status
systemctl status redis

# Test connection
redis-cli ping
```

3. Asset Compilation
```bash
# Recompile assets
bundle exec rake assets:precompile
```

## Contributing

### Development Setup
1. Fork repository
2. Create feature branch
3. Make changes
4. Run tests
5. Submit pull request

### Testing Changes
```bash
# Build and test locally
nix build .#discourse
nix-shell -p discourse --run "discourse-test"
```

## License
MIT License
