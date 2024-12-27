# Tools Directory

Contains utility scripts and tools for managing the Discourse conversion process.

## Files

### patch-manager.sh
Manages the application and tracking of system patches.

#### Purpose
- Applies patches sequentially
- Tracks applied patches
- Provides rollback capability
- Validates patch integrity

#### Usage
```bash
# Initialize patch system
./patch-manager.sh init

# Apply a specific patch
./patch-manager.sh apply <patch-file>

# Apply all patches
./patch-manager.sh apply-all

# Show patch status
./patch-manager.sh status
```

#### Configuration
```bash
# Internal variables
PATCH_DIR="${SCRIPT_DIR}/../patches"
PATCH_LOG="${PATCH_DIR}/.applied_patches"

# Color configuration
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'
```

#### Functions
- `init_patch_system()`: Initialize patch tracking
- `is_patch_applied()`: Check if patch is already applied
- `apply_patch()`: Apply a single patch
- `apply_all_patches()`: Apply all patches in sequence
- `show_status()`: Display patch status

## See Also
- [git-apply Documentation](https://git-scm.com/docs/git-apply)
- [Bash Scripting Guide](https://tldp.org/LDP/abs/html/)