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
