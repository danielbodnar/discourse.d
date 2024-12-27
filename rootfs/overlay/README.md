# Overlay Directory

Contains runtime modifications and overlay filesystem components.

## Purpose
- Provides runtime-specific modifications
- Manages temporary state
- Handles dynamic configurations
- Supports system customization

## Directory Structure
```bash
overlay/
├── etc/
│   └── discourse/
│       └── discourse.conf.d/
└── var/
    └── discourse/
        ├── tmp/
        └── run/
```

## Usage
This directory is mounted as an overlay filesystem during runtime, allowing for:
- Dynamic configuration changes
- Runtime modifications
- Temporary file storage
- State management

## Configuration
Overlay mounts are configured in SystemD units:

```ini
[Mount]
What=overlay
Where=/var/discourse
Type=overlay
Options=lowerdir=/var/discourse,upperdir=/var/discourse/overlay,workdir=/var/discourse/work
```

## See Also
- [Overlay Filesystem Documentation](https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html)
- [SystemD Mount Units](https://www.freedesktop.org/software/systemd/man/systemd.mount.html)