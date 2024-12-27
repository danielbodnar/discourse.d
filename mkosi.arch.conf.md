# Alpine Linux Build Configuration

Configuration file for building Alpine Linux-based Discourse images.

### Configuration
```ini
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

BuildPackages=
    build-base
    pkgconf

[Content]
ExtraTree=mkosi.alpine/
```

### Alpine-Specific Considerations
- Uses musl libc instead of glibc
- Requires additional build dependencies
- Optimized for minimal size
- Uses OpenRC by default (requires systemd configuration)

## /mkosi.arch.conf README
# Arch Linux Build Configuration

Configuration file for building Arch Linux-based Discourse images.

### Configuration
```ini
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

BuildPackages=
    base-devel
```

### Arch-Specific Considerations
- Rolling release distribution
- Uses systemd natively
- Includes development tools by default
- Requires explicit package selection