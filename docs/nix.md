# Nix Development Environment for Discourse

1. First, the `flake.nix` for the development environment:

```nix
{
  description = "Discourse Development Environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, flake-utils, devenv, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      {
        devShell = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [{
            packages = with pkgs; [
              ruby_3_2
              nodejs_18
              yarn
              postgresql_15
              redis
              imagemagick
              git
              curl
              wget
              gnumake
              gcc
              openssl
              readline
              zlib
              libyaml
              libxml2
              libxslt
              sqlite
              postgresql
              ruby-build
              rbenv
              bundix
            ];

            languages.ruby.enable = true;
            languages.ruby.version = "3.2.2";
            languages.javascript.enable = true;
            languages.javascript.package = pkgs.nodejs_18;

            services.postgres = {
              enable = true;
              package = pkgs.postgresql_15;
              initialDatabases = [{ name = "discourse_development"; }];
              initialScript = ''
                CREATE USER discourse WITH PASSWORD 'discourse' CREATEDB;
                GRANT ALL PRIVILEGES ON DATABASE discourse_development TO discourse;
              '';
            };

            services.redis.enable = true;

            env = {
              DISCOURSE_DEV_DB_USERNAME = "discourse";
              DISCOURSE_DEV_DB_PASSWORD = "discourse";
              DISCOURSE_DEV_DB_NAME = "discourse_development";
              DISCOURSE_DEV_REDIS_HOST = "localhost";
              DISCOURSE_DEV_REDIS_PORT = "6379";
              DISCOURSE_DEV_HOSTNAME = "localhost";
              DISCOURSE_DEV_PORT = "3000";
              RUBY_CONFIGURE_OPTS = "--with-openssl-dir=${pkgs.openssl.dev}";
            };
          }];
        };
      });
}
```

2. The NixOS configuration for running Discourse:

```nix
# configuration.nix
{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./discourse.nix
  ];

  # Basic system configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "discourse";
  networking.networkmanager.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
  ];

  # Enable services
  services.openssh.enable = true;

  # User configuration
  users.users.discourse = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
  };

  # System state version
  system.stateVersion = "23.11";
}
```

3. Discourse service configuration for NixOS:

```nix
# discourse.nix
{ config, pkgs, ... }:

let
  discourse-pkg = pkgs.stdenv.mkDerivation {
    name = "discourse";
    version = "3.2.1";

    src = pkgs.fetchFromGitHub {
      owner = "discourse";
      repo = "discourse";
      rev = "v3.2.1";
      sha256 = ""; # Add correct hash
    };

    buildInputs = with pkgs; [
      ruby_3_2
      nodejs_18
      yarn
      postgresql_15
      redis
      imagemagick
      git
      curl
      openssl
      readline
      zlib
      libyaml
      libxml2
      libxslt
    ];

    buildPhase = ''
      export HOME=$PWD
      bundle install --deployment --without development test
      yarn install --production
      RAILS_ENV=production bundle exec rake assets:precompile
    '';

    installPhase = ''
      mkdir -p $out/share/discourse
      cp -r . $out/share/discourse
    '';
  };
in
{
  services.discourse = {
    enable = true;
    package = discourse-pkg;
    hostname = "discourse.example.com";
    developer_emails = [ "admin@example.com" ];
    smtp = {
      address = "smtp.example.com";
      port = 587;
      username = "discourse@example.com";
      password = "smtp-password";
    };
    database = {
      host = "localhost";
      name = "discourse";
      username = "discourse";
      password = "discourse-db-password";
    };
    redis = {
      host = "localhost";
      port = 6379;
    };
    nginx = {
      enable = true;
      sslCertificate = "/path/to/cert.pem";
      sslCertificateKey = "/path/to/key.pem";
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_15;
    ensureDatabases = [ "discourse" ];
    ensureUsers = [{
      name = "discourse";
      ensurePermissions = {
        "DATABASE discourse" = "ALL PRIVILEGES";
      };
    }];
  };

  services.redis.enable = true;
}
```

4. DevContainer configuration using Nix:

```jsonc
// .devcontainer/devcontainer.json
{
  "name": "Discourse Nix Development",
  "build": {
    "dockerfile": "Dockerfile",
    "context": ".."
  },
  "features": {
    "ghcr.io/devcontainers/features/nix:1": {
      "extraNixConfig": "experimental-features = nix-command flakes"
    }
  },
  "mounts": [
    "source=${localEnv:HOME}/.nixconfig,target=/root/.nixconfig,type=bind,consistency=cached"
  ],
  "remoteUser": "vscode",
  "settings": {
    "terminal.integrated.defaultProfile.linux": "bash",
    "ruby.useBundler": true,
    "ruby.useLanguageServer": true,
    "ruby.lint": {
      "rubocop": true
    }
  },
  "extensions": [
    "rebornix.ruby",
    "castwide.solargraph",
    "jnoortheen.nix-ide",
    "arrterian.nix-env-selector"
  ],
  "postCreateCommand": "nix develop"
}
```

5. DevContainer Dockerfile:

```dockerfile
# .devcontainer/Dockerfile
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
```

6. Nix configuration for the DevContainer:

```nix
# .devcontainer/nix.conf
experimental-features = nix-command flakes
substituters = https://cache.nixos.org
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=
```

7. Development shell script:

```bash
#!/usr/bin/env bash
# dev.sh

# Source nix environment
if ! command -v nix &> /dev/null; then
    echo "Nix is not installed. Please install Nix first."
    exit 1
fi

# Enter development shell
exec nix develop
```

8. VS Code workspace settings:

```jsonc
// .vscode/settings.json
{
  "nix.enableLanguageServer": true,
  "ruby.useBundler": true,
  "ruby.useLanguageServer": true,
  "ruby.lint": {
    "rubocop": true
  },
  "ruby.format": "rubocop",
  "editor.formatOnSave": true,
  "files.associations": {
    "*.nix": "nix"
  }
}
```

To use this setup:

1. Install Nix:
```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

2. Enable flakes:
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

3. Clone the repository and enter the development environment:
```bash
git clone https://github.com/your/discourse-repo.git
cd discourse-repo
nix develop
```

4. Or use VS Code with the Dev Containers extension:
```bash
code discourse-repo
# Press F1 -> "Dev Containers: Open Folder in Container"
```

This setup provides:
- Reproducible development environment
- Isolated dependencies
- NixOS service configuration
- DevContainer support
- VS Code integration
- Development tools and extensions
