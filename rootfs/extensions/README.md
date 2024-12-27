# Extensions Directory

Contains distribution-specific extensions and configurations.

## Directory Structure
```bash
extensions/
├── alpine/    # Alpine Linux specific files
├── arch/      # Arch Linux specific files
├── debian/    # Debian specific files
└── ubuntu/    # Ubuntu specific files
```

## Distribution Directories

### alpine/
Alpine Linux specific configurations and files.

#### Key Files
- `etc/ImageMagick-7/policy.xml`: ImageMagick security policy
- `etc/discourse/discourse.conf.d/10-alpine.conf`: Alpine-specific settings

#### Package Requirements
```bash
# Core packages
alpine-base
imagemagick-dev
build-base
git
nginx
postgresql
postgresql-dev
redis
```

### arch/
Arch Linux specific configurations and files.

#### Key Files
- `etc/discourse/discourse.conf.d/10-arch.conf`: Arch-specific settings

#### Package Requirements
```bash
# Core packages
base
systemd
nginx
postgresql
redis
imagemagick
base-devel
git
```

### debian/
Debian specific configurations and files.

#### Key Files
- `etc/discourse/discourse.conf.d/10-debian.conf`: Debian-specific settings

#### Package Requirements
```bash
# Core packages
systemd
nginx
postgresql
redis
imagemagick
build-essential
git
```

### ubuntu/
Ubuntu specific configurations and files.

#### Key Files
- `etc/discourse/discourse.conf.d/10-ubuntu.conf`: Ubuntu-specific settings

#### Package Requirements
```bash
# Core packages
systemd
nginx
postgresql
redis
imagemagick
build-essential
git
```

## Usage
These directories are used by mkosi during the build process to add distribution-specific configurations and packages.

## See Also
- [Alpine Linux Packages](https://pkgs.alpinelinux.org/)
- [Arch Linux Packages](https://archlinux.org/packages/)
- [Debian Packages](https://packages.debian.org/)
- [Ubuntu Packages](https://packages.ubuntu.com/)
