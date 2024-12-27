# Debian Build Configuration

Configuration file for building Debian-based Discourse images.

### Configuration
```ini
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

BuildPackages=
    build-essential
    pkg-config
```

### Debian-Specific Considerations
- Stable release cycle
- Conservative package versions
- Extensive dependency management
- SystemD integration built-in
