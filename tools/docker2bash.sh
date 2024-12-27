#!/usr/bin/env bash
set -euo pipefail

# This script:

# 1. Accepts a Docker container or image as input
# 2. Extracts its configuration (env vars, volumes, ports, entrypoint, cmd)
# 3. Extracts its filesystem
# 4. Creates a set of bash scripts that replicate the container's functionality
# 5. Provides verbose and debug logging options
# 6. Includes error handling and validation

# Usage examples:

# ```bash
# # Extract from running container
# ./tools/docker2bash.sh -f my-container -t extracted -o ./output

# # Extract from image
# ./tools/docker2bash.sh -f nginx:latest -t nginx-scripts -o ./nginx

# # Extract with verbose logging
# ./tools/docker2bash.sh -f redis:alpine -t redis-custom -o ./redis -v

# # Extract with debug output
# ./tools/docker2bash.sh -f postgres:15 -t pg-scripts -o ./postgres -d
# ```

# The script creates a directory structure:

# ```plaintext
# output/
# ├── bin/
# │   └── run.sh
# ├── lib/
# │   └── common.sh
# ├── scripts/
# │   ├── 001-environment.sh
# │   ├── 002-volumes.sh
# │   ├── 003-ports.sh
# │   └── 004-entrypoint.sh
# ├── config/
# ├── rootfs/
# └── build.sh
# ```

# Script version
VERSION="1.0.0"

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

# Function to log messages
log() {
    local level="$1"
    shift
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S')] [$level] $*" >&2
}

# Function to log debug messages
debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "DEBUG" "$@"
    fi
}

# Function to log info messages
info() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        log "INFO" "$@"
    fi
}

# Function to log error messages
error() {
    log "ERROR" "$@"
    exit 1
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
    )

    for dir in "${dirs[@]}"; do
        mkdir -p "$outdir/$dir"
    done
}

parse_docker_comments() {
    local config="$1"
    local outdir="$2"

    debug "Parsing Docker image comments and history"

    local comments_file="$outdir/config/image_history.json"
    local build_steps_dir="$outdir/build_steps"
    local copy_steps_dir="$outdir/copy_steps"
    mkdir -p "$build_steps_dir" "$copy_steps_dir"

    # Create build order file
    local build_order_file="$outdir/build_order.txt"
    echo "# Build order - execute scripts in this order" > "$build_order_file"

    # Extract and parse the Comment field
    if jq -e '.[0].Comment' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Comment' <<<"$config" > "$comments_file"

        # Counter for script ordering
        local step_counter=0

        # Parse comment JSON into individual build scripts
        if [ -f "$comments_file" ]; then
            jq -r '.[] | select(.created_by != null) | {created: .created, command: .created_by, empty_layer: .empty_layer}' "$comments_file" | \
            jq -r '. | @base64' | while read -r item; do
                # Decode JSON object
                local decoded=$(echo "$item" | base64 --decode)
                local created=$(echo "$decoded" | jq -r '.created')
                local command=$(echo "$decoded" | jq -r '.command')
                local is_empty=$(echo "$decoded" | jq -r '.empty_layer')

                # Skip empty layers
                if [ "$is_empty" = "true" ]; then
                    continue
                }

                # Increment counter
                step_counter=$((step_counter + 1))
                local step_num=$(printf "%03d" $step_counter)

                # Clean up buildkit annotations
                local cleaned_command=$(echo "$command" | sed 's/|[0-9]* TARGETARCH=[^ ]* //g' | sed 's/ # buildkit//g')

                # Handle different types of commands
                if [[ "$cleaned_command" =~ ^COPY || "$cleaned_command" =~ ^ADD ]]; then
                    # Create copy script
                    local copy_script="$copy_steps_dir/${step_num}-copy.sh"
                    create_copy_script "$cleaned_command" "$copy_script" "$created"
                    echo "$copy_script" >> "$build_order_file"

                elif [[ "$cleaned_command" =~ ^RUN ]]; then
                    # Create run script
                    local run_script="$build_steps_dir/${step_num}-run.sh"
                    create_run_script "$cleaned_command" "$run_script" "$created"
                    echo "$run_script" >> "$build_order_file"

                elif [[ "$cleaned_command" =~ ^ENV ]]; then
                    # Create environment script
                    local env_script="$build_steps_dir/${step_num}-env.sh"
                    create_env_script "$cleaned_command" "$env_script" "$created"
                    echo "$env_script" >> "$build_order_file"

                elif [[ "$cleaned_command" =~ ^WORKDIR ]]; then
                    # Create workdir script
                    local workdir_script="$build_steps_dir/${step_num}-workdir.sh"
                    create_workdir_script "$cleaned_command" "$workdir_script" "$created"
                    echo "$workdir_script" >> "$build_order_file"
                fi
            done
        fi
    else
        debug "No Comment field found in image configuration"
    fi

    # Create master build script
    create_master_build_script "$outdir"

}


# Function to create copy script
create_copy_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    cat > "$script_file" << EOF
#!/bin/bash
# Generated from COPY command
# Created: $created
set -euo pipefail

# Extract source and destination from command
$(parse_copy_command "$command")

# Create destination directory
mkdir -p "\$(dirname "\$dest")"

# Copy files
if [ -d "\$src" ]; then
    cp -r "\$src"/* "\$dest/"
else
    cp "\$src" "\$dest"
fi
EOF
    chmod +x "$script_file"
}

# Function to create run script
create_run_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    # Extract the actual command from RUN instruction
    local actual_command=$(echo "$command" | sed 's/^RUN //')

    cat > "$script_file" << EOF
#!/bin/bash
# Generated from RUN command
# Created: $created
set -euo pipefail

# Execute command
$actual_command
EOF
    chmod +x "$script_file"
}

# Function to create environment script
create_env_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    # Extract environment variables
    local env_vars=$(echo "$command" | sed 's/^ENV //')

    cat > "$script_file" << EOF
#!/bin/bash
# Generated from ENV command
# Created: $created
set -euo pipefail

# Set environment variables
$(parse_env_command "$env_vars")
EOF
    chmod +x "$script_file"
}

# Function to create workdir script
create_workdir_script() {
    local command="$1"
    local script_file="$2"
    local created="$3"

    # Extract directory
    local dir=$(echo "$command" | sed 's/^WORKDIR //')

    cat > "$script_file" << EOF
#!/bin/bash
# Generated from WORKDIR command
# Created: $created
set -euo pipefail

# Create and change to directory
mkdir -p $dir
cd $dir
EOF
    chmod +x "$script_file"
}

# Function to parse COPY command
parse_copy_command() {
    local command="$1"
    local src=$(echo "$command" | awk '{print $2}')
    local dest=$(echo "$command" | awk '{print $3}')

    # Handle --from=stage syntax
    if [[ "$src" =~ --from= ]]; then
        local stage=$(echo "$src" | cut -d= -f2)
        src=$(echo "$command" | awk '{print $3}')
        dest=$(echo "$command" | awk '{print $4}')
        echo "# Copy from stage: $stage"
    fi

    echo "src=\"$src\""
    echo "dest=\"$dest\""
}

# Function to parse ENV command
parse_env_command() {
    local env_vars="$1"

    # Handle both space-separated and equals-separated formats
    if [[ "$env_vars" =~ = ]]; then
        # Equals-separated format
        echo "export $env_vars"
    else
        # Space-separated format
        local key=$(echo "$env_vars" | awk '{print $1}')
        local value=$(echo "$env_vars" | cut -d' ' -f2-)
        echo "export $key=\"$value\""
    fi
}


# Function to create master build script
create_master_build_script() {
    local outdir="$1"

    cat > "$outdir/build.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load build order
BUILD_ORDER_FILE="$SCRIPT_DIR/build_order.txt"

if [ ! -f "$BUILD_ORDER_FILE" ]; then
    echo "Error: Build order file not found"
    exit 1
fi

# Execute scripts in order
while IFS= read -r script; do
    # Skip comments and empty lines
    [[ "$script" =~ ^#.*$ ]] && continue
    [[ -z "$script" ]] && continue

    echo "Executing: $script"
    if [ -x "$SCRIPT_DIR/$script" ]; then
        "$SCRIPT_DIR/$script" || {
            echo "Error executing $script"
            exit 1
        }
    else
        echo "Warning: $script not found or not executable"
    fi
done < "$BUILD_ORDER_FILE"
EOF
    chmod +x "$outdir/build.sh"
}

# Function to extract container configuration
extract_container_config() {
    local container="$1"
    local outdir="$2"

    debug "Extracting configuration from container: $container"

    # Get container info
    local config
    if ! config=$(docker inspect "$container"); then
        if [ "$CONTINUE_ON_ERROR" = true ]; then
            warn "Failed to inspect container/image: $container"
            return
        else
            error "Failed to inspect container/image: $container"
        fi
    fi

    # Extract environment variables
    debug "Extracting environment variables"
    if jq -e '.[0].Config.Env' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Env[]?' <<<"$config" | while read -r env; do
            if [ -n "$env" ]; then
                echo "export $env" >> "$outdir/scripts/001-environment.sh"
            fi
        done
    else
        debug "No environment variables found"
    fi

    # Extract volumes
    debug "Extracting volume configuration"
    if jq -e '.[0].Config.Volumes' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Volumes | if . == null then {} else . end | keys[]?' <<<"$config" | while read -r volume; do
            if [ -n "$volume" ]; then
                echo "mkdir -p \"$volume\"" >> "$outdir/scripts/002-volumes.sh"
            fi
        done
    else
        debug "No volume configuration found"
    fi

    # Extract ports
    debug "Extracting port configuration"
    if jq -e '.[0].Config.ExposedPorts' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.ExposedPorts | if . == null then {} else . end | keys[]?' <<<"$config" | while read -r port; do
            if [ -n "$port" ]; then
                echo "# Exposed port: $port" >> "$outdir/scripts/003-ports.sh"
            fi
        done
    else
        debug "No exposed ports found"
    fi

    # Extract entrypoint and cmd
    debug "Extracting entrypoint and command"
    echo "ENTRYPOINT_ARGS=()" > "$outdir/scripts/004-entrypoint.sh"
    echo "CMD_ARGS=()" >> "$outdir/scripts/004-entrypoint.sh"

    if jq -e '.[0].Config.Entrypoint' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Entrypoint[]?' <<<"$config" | while read -r entry; do
            if [ -n "$entry" ]; then
                echo "ENTRYPOINT_ARGS+=(\"$entry\")" >> "$outdir/scripts/004-entrypoint.sh"
            fi
        done
    fi

    if jq -e '.[0].Config.Cmd' <<<"$config" >/dev/null 2>&1; then
        jq -r '.[0].Config.Cmd[]?' <<<"$config" | while read -r cmd; do
            if [ -n "$cmd" ]; then
                echo "CMD_ARGS+=(\"$cmd\")" >> "$outdir/scripts/004-entrypoint.sh"
            fi
        done
    fi

    # Parse image comments if enabled
    if [ "$PARSE_COMMENTS" = true ]; then
        parse_docker_comments "$config" "$outdir"
    fi
}

# Function to extract filesystem
extract_filesystem() {
    local container="$1"
    local outdir="$2"

    debug "Extracting filesystem from container: $container"

    # Create temporary container if image is provided
    local temp_container=""
    if ! docker inspect "$container" --format '{{.State}}' >/dev/null 2>&1; then
        debug "Creating temporary container from image: $container"
        temp_container=$(docker create "$container")
        container=$temp_container
    fi

    # Export container filesystem
    debug "Exporting container filesystem"
    docker export "$container" | tar -x -C "$outdir/rootfs"

    # Cleanup temporary container
    if [ -n "$temp_container" ]; then
        debug "Removing temporary container"
        docker rm "$temp_container"
    fi
}

# Function to create runtime scripts
create_runtime_scripts() {
    local outdir="$1"
    local name="$2"

    debug "Creating runtime scripts"

    # Create common library
    cat > "$outdir/lib/common.sh" << 'EOF'
#!/usr/bin/env bash

# Common functions
log() {
    echo "[$(date -u '+%Y-%m-%d %H:%M:%S')] $*" >&2
}

error() {
    log "ERROR: $*"
    exit 1
}

# Environment setup
setup_environment() {
    # Load environment variables
    if [ -f "$SCRIPT_DIR/scripts/001-environment.sh" ]; then
        source "$SCRIPT_DIR/scripts/001-environment.sh"
    fi
}

# Volume setup
setup_volumes() {
    if [ -f "$SCRIPT_DIR/scripts/002-volumes.sh" ]; then
        source "$SCRIPT_DIR/scripts/002-volumes.sh"
    fi
}

# Port setup
setup_ports() {
    if [ -f "$SCRIPT_DIR/scripts/003-ports.sh" ]; then
        source "$SCRIPT_DIR/scripts/003-ports.sh"
    fi
}

# Entrypoint setup
setup_entrypoint() {
    if [ -f "$SCRIPT_DIR/scripts/004-entrypoint.sh" ]; then
        source "$SCRIPT_DIR/scripts/004-entrypoint.sh"
    fi
}
EOF

    # Create main script
    cat > "$outdir/bin/run.sh" << EOF
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")/.." && pwd)"
source "\$SCRIPT_DIR/lib/common.sh"

# Setup environment
setup_environment

# Setup volumes
setup_volumes

# Setup ports
setup_ports

# Setup entrypoint
setup_entrypoint

# Execute command
if [ \${#ENTRYPOINT_ARGS[@]} -gt 0 ]; then
    exec "\${ENTRYPOINT_ARGS[@]}" "\$@"
elif [ \${#CMD_ARGS[@]} -gt 0 ]; then
    exec "\${CMD_ARGS[@]}" "\$@"
else
    error "No command specified"
fi
EOF

    chmod +x "$outdir/bin/run.sh"

    # Create build script
    cat > "$outdir/build.sh" << EOF
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"

# Execute all scripts in order
for script in "\$SCRIPT_DIR"/scripts/*.sh; do
    if [ -x "\$script" ]; then
        source "\$script"
    fi
done
EOF

    chmod +x "$outdir/build.sh"
}

# Add new function for handling multi-stage builds
handle_multi_stage() {
    local image="$1"
    local outdir="$2"

    debug "Checking for multi-stage build"

    # Create stages directory
    mkdir -p "$outdir/stages"

    # Get all stages
    local stages
    stages=$(docker history "$image" --format "{{.CreatedBy}}" | grep -i "^FROM" || true)

    if [ -n "$stages" ]; then
        debug "Found multi-stage build"

        # Process each stage
        local stage_num=0
        while read -r stage; do
            stage_num=$((stage_num + 1))
            local stage_dir="$outdir/stages/stage${stage_num}"
            mkdir -p "$stage_dir"

            # Extract stage information
            echo "# Stage $stage_num: $stage" > "$stage_dir/stage.info"

            # Try to extract intermediate container if possible
            local stage_image
            stage_image=$(echo "$stage" | awk '{print $2}')
            if docker image inspect "$stage_image" >/dev/null 2>&1; then
                extract_container_config "$stage_image" "$stage_dir"
            fi
        done <<< "$stages"
    else
        debug "No multi-stage build detected"
    fi
}

# Update main function to include new flags
main() {
    local from=""
    local to=""
    local outdir=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--from)
                from="$2"
                shift 2
                ;;
            -t|--to)
                to="$2"
                shift 2
                ;;
            -o|--outdir)
                outdir="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -d|--debug)
                DEBUG=true
                shift
                ;;
            -c|--continue)
                CONTINUE_ON_ERROR=true
                shift
                ;;
            -p|--parse-comments)
                PARSE_COMMENTS=true
                shift
                ;;
            -h|--help)
                usage
                ;;
            -V|--version)
                version
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done


    # Validate required arguments
    if [ -z "$from" ] || [ -z "$to" ] || [ -z "$outdir" ]; then
        error "Missing required arguments"
    fi

    # Create output directory
    info "Creating directory structure"
    create_directory_structure "$outdir"

    # Extract container configuration
    info "Extracting container configuration"
    extract_container_config "$from" "$outdir"

    # Extract filesystem
    info "Extracting filesystem"
    extract_filesystem "$from" "$outdir"

    # Create runtime scripts
    info "Creating runtime scripts"
    create_runtime_scripts "$outdir" "$to"

    # Make all scripts executable
    find "$outdir/scripts" -type f -name "*.sh" -exec chmod +x {} \;

    # Add multi-stage handling
    if [[ "$from" =~ : ]]; then
        handle_multi_stage "$from" "$outdir"
    fi

    info "Extraction complete: $outdir"
}

# Run main function
main "$@"

# ./tools/docker2bash.sh \
#     -f bitnami/discourse:3.2.1 \
#     -t bitnami-discourse-3.2.1 \
#     -o ./.out \
#     -v -d -c -p
