# Ubuntu Build Configuration

Configuration file for building Ubuntu-based Discourse images.

### Configuration
```ini
[Distribution]
Release=jammy

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

### Ubuntu-Specific Considerations
- Based on Debian
- More recent package versions
- Additional security features
- Snap package support (not used in this build)