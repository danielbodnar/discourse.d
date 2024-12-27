
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/00-config.sh"

generate_mkosi_config() {
    log "Generating mkosi configurations..."

    generate_base_config
    generate_distro_configs
}

generate_base_config() {
    cat > "${BASE_DIR}/mkosi.defaults.conf" << EOF
[Distribution]
Distribution=@DISTRIBUTION@
Release=@RELEASE@

[Output]
Format=gpt_ext4
Bootable=no
OutputDirectory=output
WorkspaceDirectory=work
BuildDirectory=build

[Content]
MakeInitrd=no
RemoveFiles=/var/cache/apt /var/lib/apt/lists
Environment=
    LANG=C.UTF-8
    LC_ALL=C.UTF-8

[Validation]
CheckSum=yes
Sign=no

[Host]
QemuHeadless=yes
EOF
}

generate_distro_configs() {
    # Alpine configuration
    cat > "${BASE_DIR}/mkosi.alpine.conf" << EOF
[Distribution]
Release=edge

[Content]
Packages=
    alpine-base
    imagemagick-dev
    build-base
    git
    nginx
    postgresql
    postgresql-dev
    redis
    yaml-dev
    zlib-dev
    libxml2-dev
    libxslt-dev
    readline-dev
    openssl-dev
    bash
    sudo
EOF

    # Arch configuration
    cat > "${BASE_DIR}/mkosi.arch.conf" << EOF
[Distribution]
Release=latest

[Content]
Packages=
    base
    systemd
    nginx
    postgresql
    redis
    imagemagick
    base-devel
    git
    sudo
EOF

    # Debian configuration
    cat > "${BASE_DIR}/mkosi.debian.conf" << EOF
[Distribution]
Release=bookworm

[Content]
Packages=
    systemd
    nginx
    postgresql
    redis
    imagemagick
    build-essential
    git
    sudo
EOF
}
