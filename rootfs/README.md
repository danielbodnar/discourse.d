# Root Filesystem Directory

Contains the layered root filesystem structure for the Discourse conversion.

## Directory Structure
```bash
rootfs/
├── base/           # Common base filesystem
├── extensions/     # Distribution-specific extensions
└── overlay/        # Runtime overlays
```

## Subdirectories

### base/
Contains the common base filesystem shared across all distributions.

#### Key Directories
- `etc/`: System configuration files
- `usr/`: System binaries and libraries
- `var/`: Variable data

#### Important Files
- `etc/discourse/discourse.conf`: Base configuration
- `etc/systemd/system/discourse.service`: SystemD service definition
- `usr/lib/discourse/`: Discourse-specific scripts and utilities

### extensions/
Distribution-specific files and configurations.

#### Supported Distributions
- `alpine/`: Alpine Linux specific files
- `arch/`: Arch Linux specific files
- `debian/`: Debian specific files
- `ubuntu/`: Ubuntu specific files

### overlay/
Runtime modifications and temporary files.

#### Purpose
- Contains runtime-specific modifications
- Manages temporary state
- Handles dynamic configurations

## Usage
This directory is used by mkosi to build the final system image:
```bash
mkosi -f mkosi.defaults.conf build
```

## See Also
- [mkosi Documentation](https://github.com/systemd/mkosi/tree/main/docs)
- [SystemD Portable Services](https://systemd.io/PORTABLE_SERVICES/)