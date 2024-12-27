# tools/lib/common.sh
#!/usr/bin/env bash

# Script version and defaults
VERSION="1.0.0"
CONTINUE_ON_ERROR=${CONTINUE_ON_ERROR:-false}
PARSE_COMMENTS=${PARSE_COMMENTS:-true}
DEBUG=${DEBUG:-false}
VERBOSE=${VERBOSE:-false}

# Function to display usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] --from SOURCE --to TARGET --outdir DIR

Extract Docker container/image configuration into bash scripts.

Options:
    -f, --from      Source container/image
    -t, --to        Target name for generated scripts
    -o, --outdir    Output directory for generated files
    -v, --verbose   Enable verbose output
    -d, --debug     Enable debug mode
    -c, --continue  Continue on errors (skip failed extractions)
    -p, --parse-comments  Parse Docker image comments/history
    -h, --help      Display this help message
    -V, --version   Display version information

Examples:
    $(basename "$0") -f nginx:latest -t my-nginx -o ./output
    $(basename "$0") -f running-container -t extracted -o ./scripts
    $(basename "$0") --from redis:alpine --to redis-custom --outdir ./build

Report bugs to: https://github.com/your-repo/issues
EOF
    exit 1
}

# Function to display version
version() {
    echo "$(basename "$0") version $VERSION"
    exit 0
}

# Function to ensure required commands exist
check_requirements() {
    local required_commands=(
        "docker"
        "jq"
        "tar"
        "base64"
        "sed"
        "awk"
    )

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd"
        fi
    done
}

# Function to create directory structure
create_directory_structure() {
    local outdir="$1"
    local dirs=(
        "bin"
        "lib"
        "scripts"
        "config"
        "rootfs"
        "build_steps"
        "copy_steps"
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$outdir/$dir"
    done
}

# Function to cleanup temporary files
cleanup() {
    local temp_container="$1"
    if [ -n "$temp_container" ]; then
        debug "Removing temporary container: $temp_container"
        docker rm "$temp_container" >/dev/null 2>&1 || true
    fi
}

# Set trap for cleanup
trap_cleanup() {
    local temp_container="$1"
    trap 'cleanup "$temp_container"' EXIT
}
