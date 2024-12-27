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
