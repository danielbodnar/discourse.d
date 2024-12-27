#!/usr/bin/env bash
set -euo pipefail


# This script:

# 1. Takes a Dockerfile and output directory as input
# 2. Creates a modular build system with:
#    - `build.sh`: Main build script
#    - `run.sh`: Runtime execution script
#    - `lib/common.sh`: Common functions library
#    - `scripts/`: Numbered build step scripts
#    - `bin/`: Runtime executables

# 3. Converts each Dockerfile command to a separate bash script:
#    - RUN → Direct shell commands
#    - ENV → Export statements
#    - WORKDIR → Directory changes
#    - COPY/ADD → File operations
#    - USER → User management
#    - VOLUME → Directory creation
#    - EXPOSE → Port documentation
#    - ENTRYPOINT/CMD → Runtime scripts

# Usage example:
# ```bash
# chmod +x dockerfile2bash.sh
# ./dockerfile2bash.sh --dockerfile ./Dockerfile --outdir ./build

# # Build the system
# ./build/build.sh

# # Run the application
# ./build/run.sh
# ```

# The resulting structure will be:
# ```
# build/
# ├── bin/
# │   └── entrypoint.sh
# ├── lib/
# │   └── common.sh
# ├── scripts/
# │   ├── 001-env.sh
# │   ├── 002-run.sh
# │   └── ...
# ├── build.sh
# └── run.sh
# ```

# This approach:
# - Decouples build logic from container runtime
# - Makes each step independently testable
# - Allows for easier debugging and modification
# - Provides better error handling and logging
# - Makes the build process more transparent



# Function to display usage
usage() {
    cat << EOF
Usage: $0 --dockerfile DOCKERFILE --outdir OUTPUT_DIR

Converts Dockerfile commands into modular bash scripts.

Options:
    --dockerfile    Path to Dockerfile
    --outdir       Output directory for build scripts

Example:
    $0 --dockerfile ./Dockerfile --outdir ./build
EOF
    exit 1
}

# Function to parse Dockerfile and create build scripts
parse_dockerfile() {
    local dockerfile="$1"
    local outdir="$2"

    # Create directory structure
    mkdir -p "$outdir"/{bin,lib,scripts}

    # Create main build script
    cat > "$outdir/build.sh" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Process all build steps in order
for script in "${SCRIPT_DIR}/scripts/"*.sh; do
    if [ -x "$script" ]; then
        log "Executing $(basename "$script")..."
        "$script"
    fi
done
EOF
    chmod +x "$outdir/build.sh"

    # Create common library functions
    cat > "$outdir/lib/common.sh" << 'EOF'
#!/usr/bin/env bash

# Logging functions
log() { echo "[$(date -u '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
error() { log "ERROR: $*"; exit 1; }
success() { log "SUCCESS: $*"; }

# Environment setup
setup_env() {
    export WORKDIR="${WORKDIR:-/}"
    export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
}

# Function to run commands as specific user
run_as_user() {
    local user="$1"
    shift
    if [ "$(id -u)" = "0" ]; then
        su -s /bin/bash -c "$*" "$user"
    else
        "$@"
    fi
}

# Function to ensure directory exists with correct permissions
ensure_dir() {
    local dir="$1"
    local user="${2:-}"
    local group="${3:-$user}"
    local mode="${4:-755}"

    mkdir -p "$dir"
    if [ -n "$user" ]; then
        chown "$user:$group" "$dir"
        chmod "$mode" "$dir"
    fi
}

# Function to copy files with permissions
copy_files() {
    local src="$1"
    local dst="$2"
    local user="${3:-}"
    local group="${4:-$user}"
    local mode="${5:-644}"

    cp -R "$src" "$dst"
    if [ -n "$user" ]; then
        chown -R "$user:$group" "$dst"
        chmod -R "$mode" "$dst"
    fi
}

# Load environment variables from file
load_env() {
    local env_file="$1"
    if [ -f "$env_file" ]; then
        set -a
        source "$env_file"
        set +a
    fi
}

setup_env
EOF

    # Initialize script counter
    local counter=0
    local current_script=""
    local in_multiline=false
    local multiline_cmd=""

    # Read Dockerfile line by line
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
            continue
        fi

        # Handle multiline commands
        if [[ "$line" =~ \\ ]]; then
            in_multiline=true
            multiline_cmd+="${line%\\} "
            continue
        elif [ "$in_multiline" = true ]; then
            line="$multiline_cmd$line"
            multiline_cmd=""
            in_multiline=false
        fi

        # Parse Dockerfile commands
        if [[ "$line" =~ ^[A-Z]+ ]]; then
            cmd="${line%% *}"
            args="${line#* }"

            # Create new script for each command
            counter=$((counter + 1))
            current_script="$outdir/scripts/$(printf "%03d" $counter)-${cmd,,}.sh"

            case "$cmd" in
                FROM)
                    # Skip FROM commands as they're not needed in scripts
                    continue
                    ;;

                RUN)
                    # Convert RUN commands directly to bash
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: RUN $args
$args
EOF
                    ;;

                ENV)
                    # Convert ENV to export statements
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: ENV $args
EOF
                    # Handle space-separated and equals-separated ENV
                    if [[ "$args" =~ = ]]; then
                        echo "export $args" >> "$current_script"
                    else
                        read -r key value <<< "$args"
                        echo "export $key=\"$value\"" >> "$current_script"
                    fi
                    ;;

                WORKDIR)
                    # Convert WORKDIR to cd and export
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: WORKDIR $args
export WORKDIR="$args"
cd "$args"
EOF
                    ;;

                COPY|ADD)
                    # Convert COPY/ADD to cp commands
                    read -r src dst <<< "$args"
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: $cmd $args
ensure_dir "\$(dirname "$dst")"
copy_files "$src" "$dst"
EOF
                    ;;

                USER)
                    # Convert USER to export and chown commands
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: USER $args
export CURRENT_USER="$args"
if [ "\$(id -u)" = "0" ]; then
    if ! getent passwd "$args" >/dev/null; then
        useradd -r -s /sbin/nologin "$args"
    fi
fi
EOF
                    ;;

                VOLUME)
                    # Convert VOLUME to directory creation
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: VOLUME $args
EOF
                    # Parse JSON array or space-separated volumes
                    if [[ "$args" =~ ^\[ ]]; then
                        eval "volumes=$args"
                        for vol in "${volumes[@]}"; do
                            echo "ensure_dir \"$vol\" \"\${CURRENT_USER:-root}\"" >> "$current_script"
                        done
                    else
                        for vol in $args; do
                            echo "ensure_dir \"$vol\" \"\${CURRENT_USER:-root}\"" >> "$current_script"
                        done
                    fi
                    ;;

                EXPOSE)
                    # Create documentation for exposed ports
                    cat > "$current_script" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: EXPOSE $args
# Note: Port exposure is handled by container runtime
export EXPOSED_PORTS="\${EXPOSED_PORTS:-} $args"
EOF
                    ;;

                ENTRYPOINT|CMD)
                    # Convert ENTRYPOINT/CMD to executable script
                    cat > "$outdir/bin/entrypoint.sh" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../lib/common.sh"

# Generated from: $cmd $args
EOF
                    # Parse JSON array or shell form
                    if [[ "$args" =~ ^\[ ]]; then
                        eval "commands=$args"
                        printf '%q ' "${commands[@]}" >> "$outdir/bin/entrypoint.sh"
                    else
                        echo "$args" >> "$outdir/bin/entrypoint.sh"
                    fi
                    chmod +x "$outdir/bin/entrypoint.sh"
                    ;;
            esac

            # Make script executable
            if [ -f "$current_script" ]; then
                chmod +x "$current_script"
            fi
        fi
    done < "$dockerfile"

    # Create run script
    cat > "$outdir/run.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Execute entrypoint if it exists
if [ -x "${SCRIPT_DIR}/bin/entrypoint.sh" ]; then
    exec "${SCRIPT_DIR}/bin/entrypoint.sh" "$@"
else
    error "No entrypoint script found"
fi
EOF
    chmod +x "$outdir/run.sh"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dockerfile)
            dockerfile="$2"
            shift 2
            ;;
        --outdir)
            outdir="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Validate required arguments
if [ -z "${dockerfile:-}" ] || [ -z "${outdir:-}" ]; then
    usage
fi

# Convert Dockerfile to scripts
parse_dockerfile "$dockerfile" "$outdir"

echo "Done! Build scripts created in $outdir"
echo "To build: $outdir/build.sh"
echo "To run: $outdir/run.sh"
