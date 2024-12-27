#!/usr/bin/env bash
set -euo pipefail


# ```plaintext
# tools/
# ├── docker2bash.sh              # Main script
# └── lib/
#     ├── common.sh              # Common functions and variables
#     ├── logging.sh             # Logging functions
#     ├── docker.sh              # Docker-related functions
#     ├── filesystem.sh          # Filesystem operations
#     ├── parsers.sh             # Command parsing functions
#     ├── generators.sh          # Script generation functions
#     └── scripts/
#         ├── copy.sh.template   # Template for copy scripts
#         ├── run.sh.template    # Template for run scripts
#         ├── env.sh.template    # Template for env scripts
#         └── workdir.sh.template # Template for workdir scripts
# ```

# The main script would become much simpler:

# ```bash
# #!/usr/bin/env bash
# set -euo pipefail

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# LIB_DIR="${SCRIPT_DIR}/lib"

# # Source all library files
# for lib in "${LIB_DIR}"/*.sh; do
#     source "$lib"
# done

# # Main execution
# main "$@"
# ```

# Would you like me to show you how to break down each component into its respective library file?

# The key improvements would be:
# 1. Better separation of concerns
# 2. More maintainable code
# 3. Reusable functions
# 4. Template-based script generation
# 5. Easier testing
# 6. Better error handling
# 7. More consistent logging
# 8. Cleaner main script


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${SCRIPT_DIR}/lib"

# Source all library files
for lib in "${LIB_DIR}"/*.sh; do
    source "$lib"
done

# Main execution
main "$@"
