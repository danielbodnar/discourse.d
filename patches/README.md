# Patches Directory

Contains sequential patches for building the Discourse conversion system.

## Purpose
Manages the incremental build process through versioned patches that can be applied in sequence.

## Structure
```bash
patches/
├── .applied_patches     # Tracks successfully applied patches
├── 0001-*.patch        # Patch management system
├── 0002-*.patch        # Initial project structure
├── 0003-*.patch        # Paths and volumes
└── *.patch             # Additional feature patches
```

## Current Patches

### 0001-add-patch-management.patch
- Implements patch management system
- Adds tracking capabilities
- Provides rollback functionality

### 0002-initial-project-structure.patch
- Creates base directory structure
- Implements configuration system
- Sets up basic utilities

### 0003-add-discourse-paths-and-volumes.patch
- Configures Discourse paths
- Implements volume management
- Sets up mount points

## Usage
```bash
# Apply specific patch
./tools/patch-manager.sh apply 0001-add-patch-management.patch

# Apply all patches
./tools/patch-manager.sh apply-all

# Check patch status
./tools/patch-manager.sh status
```

## See Also
- [git-apply Documentation](https://git-scm.com/docs/git-apply)
- [Patch Format](https://git-scm.com/docs/git-format-patch)