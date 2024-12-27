
# Tools Directory

Contains utility scripts for managing the build process.

## Scripts

### patch-manager.sh
Manages the sequential application of patches for the build system.

#### Features
- Tracks applied patches
- Validates patch integrity
- Handles rollbacks
- Provides status reporting

#### Usage
```bash
./patch-manager.sh init        # Initialize patch system
./patch-manager.sh apply PATCH # Apply specific patch
./patch-manager.sh apply-all   # Apply all patches
./patch-manager.sh status      # Show patch status
```
