
# Discourse Container Migration Project

## Overview
Tool for converting Discourse Docker containers to SystemD portable services and system extensions.

## Directory Structure
```
discourse-conversion/
├── convert.sh                 # Main conversion script
├── build.sh                   # Build system script
├── tools/                     # Utility scripts
├── lib/                      # Core libraries
├── patches/                  # Sequential patches
├── rootfs/                   # Root filesystem
├── config/                   # Environment configs
├── src/                      # Source files
└── test/                     # Test scripts
```

## Quick Start
```bash
# Initialize project
./tools/patch-manager.sh init

# Apply all patches
./tools/patch-manager.sh apply-all

# Build root filesystem
./build.sh build

# Test build
./build.sh test alpine
```

## Project Layout
- `lib/`: Core library scripts
- `tools/`: Utility scripts and tools
- `patches/`: Sequential patch files
- `rootfs/`: Root filesystem structure
- `config/`: Configuration files
- `src/`: Source code and templates
- `test/`: Test scripts and utilities

## License
Project specific license information goes here.
