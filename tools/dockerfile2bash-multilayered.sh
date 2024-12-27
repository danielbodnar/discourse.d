#!/usr/bin/env bash
set -euo pipefail

# Add to the previous script's functions
parse_multistage_dockerfile() {
    local dockerfile="$1"
    local outdir="$2"

    # Create stages directory
    mkdir -p "$outdir/stages"

    # Variables for stage tracking
    local current_stage=""
    local stage_counter=0
    local -A stage_names
    local -A stage_deps

    # First pass: identify stages and their dependencies
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
            continue
        fi

        # Handle FROM instructions
        if [[ "$line" =~ ^FROM ]]; then
            stage_counter=$((stage_counter + 1))

            # Parse FROM instruction
            if [[ "$line" =~ ^FROM[[:space:]]+(.+)[[:space:]]+AS[[:space:]]+(.+)$ ]]; then
                # Named stage
                local base="${BASH_REMATCH[1]}"
                local name="${BASH_REMATCH[2]}"
                stage_names[$stage_counter]="$name"
                stage_deps[$stage_counter]="$base"
            else
                # Unnamed stage
                local base="${line#FROM }"
                stage_names[$stage_counter]="stage${stage_counter}"
                stage_deps[$stage_counter]="$base"
            fi

            current_stage="$stage_counter"

            # Create stage directory
            mkdir -p "$outdir/stages/${stage_names[$current_stage]}"
        fi
    done < "$dockerfile"

    # Create stage dependency graph
    local -A stage_graph
    for stage in "${!stage_deps[@]}"; do
        local dep="${stage_deps[$stage]}"
        # Check if dependency is a named stage
        for s in "${!stage_names[@]}"; do
            if [ "${stage_names[$s]}" = "$dep" ]; then
                stage_graph[$stage]="$s"
                break
            fi
        done
    done

    # Create build order file
    cat > "$outdir/build-order.txt" << EOF
# Build order for multi-stage build
# Generated on $(date -u)

EOF

    # Add stages in dependency order
    for stage in "${!stage_names[@]}"; do
        echo "${stage_names[$stage]}" >> "$outdir/build-order.txt"
    done

    # Second pass: create build scripts for each stage
    current_stage=""
    while IFS= read -r line || [ -n "$line" ]; do
        if [[ -z "$line" ]] || [[ "$line" =~ ^# ]]; then
            continue
        fi

        if [[ "$line" =~ ^FROM ]]; then
            if [[ "$line" =~ ^FROM[[:space:]]+(.+)[[:space:]]+AS[[:space:]]+(.+)$ ]]; then
                current_stage="${BASH_REMATCH[2]}"
            else
                stage_counter=$((stage_counter + 1))
                current_stage="stage${stage_counter}"
            fi

            # Create stage build script
            cat > "$outdir/stages/$current_stage/build.sh" << EOF
#!/bin/bash
set -euo pipefail

STAGE_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
source "\${STAGE_DIR}/../../lib/common.sh"

# Build stage: $current_stage
# Base: ${stage_deps[$stage_counter]}

EOF
            chmod +x "$outdir/stages/$current_stage/build.sh"

            # Create stage lib directory
            mkdir -p "$outdir/stages/$current_stage/lib"

            continue
        fi

        # Process other Dockerfile commands for current stage
        if [ -n "$current_stage" ]; then
            process_dockerfile_command "$line" "$outdir/stages/$current_stage"
        fi
    done < "$dockerfile"

    # Create main build script that handles all stages
    cat > "$outdir/build.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Function to build a stage
build_stage() {
    local stage="$1"
    local stage_dir="${SCRIPT_DIR}/stages/${stage}"

    if [ ! -d "$stage_dir" ]; then
        error "Stage directory not found: $stage_dir"
    }

    log "Building stage: $stage"
    if [ -x "$stage_dir/build.sh" ]; then
        "$stage_dir/build.sh"
    else
        error "Build script not found for stage: $stage"
    fi
}

# Build all stages in order
while read -r stage || [ -n "$stage" ]; do
    # Skip comments and empty lines
    [[ "$stage" =~ ^#.*$ ]] && continue
    [[ -z "$stage" ]] && continue

    build_stage "$stage"
done < "${SCRIPT_DIR}/build-order.txt"
EOF
    chmod +x "$outdir/build.sh"

    # Create artifact copying script
    cat > "$outdir/copy-artifacts.sh" << 'EOF'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Copy artifacts between stages
copy_stage_artifact() {
    local from_stage="$1"
    local to_stage="$2"
    local src="$3"
    local dst="$4"

    local from_dir="${SCRIPT_DIR}/stages/${from_stage}/rootfs"
    local to_dir="${SCRIPT_DIR}/stages/${to_stage}/rootfs"

    # Ensure source exists
    if [ ! -e "${from_dir}/${src}" ]; then
        error "Source artifact not found: ${from_dir}/${src}"
    }

    # Create destination directory
    mkdir -p "$(dirname "${to_dir}/${dst}")"

    # Copy artifact
    cp -a "${from_dir}/${src}" "${to_dir}/${dst}"
}
EOF
    chmod +x "$outdir/copy-artifacts.sh"
}

# Function to process individual Dockerfile commands for a stage
process_dockerfile_command() {
    local line="$1"
    local stage_dir="$2"

    # Extract command and arguments
    local cmd="${line%% *}"
    local args="${line#* }"

    # Create scripts directory for stage if it doesn't exist
    mkdir -p "$stage_dir/scripts"

    # Get next script number
    local script_num=$(find "$stage_dir/scripts" -type f -name "*.sh" | wc -l)
    script_num=$((script_num + 1))

    # Create script based on command type
    case "$cmd" in
        COPY)
            # Handle COPY --from=stage syntax
            if [[ "$args" =~ --from=([^[:space:]]+)[[:space:]]+(.*) ]]; then
                local from_stage="${BASH_REMATCH[1]}"
                local copy_args="${BASH_REMATCH[2]}"
                cat > "$stage_dir/scripts/$(printf "%03d" $script_num)-copy-from.sh" << EOF
#!/bin/bash
set -euo pipefail
source "\$(dirname "\$0")/../../lib/common.sh"

# Copy from stage: $from_stage
source "\${SCRIPT_DIR}/copy-artifacts.sh"
copy_stage_artifact "$from_stage" "\${STAGE_NAME}" $copy_args
EOF
            else
                # Regular COPY command
                create_copy_script "$stage_dir/scripts/$(printf "%03d" $script_num)-copy.sh" "$args"
            fi
            ;;
        *)
            # Use existing command processing logic
            create_command_script "$stage_dir/scripts/$(printf "%03d" $script_num)-${cmd,,}.sh" "$cmd" "$args"
            ;;
    esac
}

# Update main script to handle multi-stage builds
main() {
    local dockerfile="$1"
    local outdir="$2"

    # Create base directory structure
    mkdir -p "$outdir"/{lib,bin}

    # Copy common library functions
    create_common_lib "$outdir/lib/common.sh"

    # Parse multi-stage Dockerfile
    parse_multistage_dockerfile "$dockerfile" "$outdir"

    log "Multi-stage build scripts created in $outdir"
    log "Build stages in order:"
    cat "$outdir/build-order.txt"
}

# Example usage:
# ./dockerfile2bash.sh --dockerfile ./Dockerfile --outdir ./build


# 1. Supports multi-stage builds by:
#    - Creating separate directories for each build stage
#    - Tracking stage dependencies
#    - Handling `COPY --from=stage` commands
#    - Managing build order

# 2. Creates a directory structure like:
# ```
# build/
# ├── stages/
# │   ├── builder/
# │   │   ├── scripts/
# │   │   ├── lib/
# │   │   └── build.sh
# │   ├── final/
# │   │   ├── scripts/
# │   │   ├── lib/
# │   │   └── build.sh
# │   └── ...
# ├── lib/
# │   └── common.sh
# ├── build-order.txt
# ├── build.sh
# └── copy-artifacts.sh
# ```

# 3. Handles stage dependencies:
#    - Tracks which stages depend on others
#    - Creates correct build order
#    - Manages artifact copying between stages

# 4. Provides utilities for:
#    - Copying artifacts between stages
#    - Managing stage-specific environment variables
#    - Handling stage-specific build commands

# Example multi-stage Dockerfile:
# ```dockerfile
# FROM alpine:3.19 AS builder
# RUN apk add --no-cache gcc make
# COPY src /src
# RUN cd /src && make

# FROM alpine:3.19
# COPY --from=builder /src/myapp /usr/local/bin/
# CMD ["myapp"]
# ```

# Would become:
# ```
# build/
# ├── stages/
# │   ├── builder/
# │   │   ├── scripts/
# │   │   │   ├── 001-run.sh
# │   │   │   ├── 002-copy.sh
# │   │   │   └── 003-run.sh
# │   │   └── build.sh
# │   └── final/
# │       ├── scripts/
# │       │   ├── 001-copy-from.sh
# │       │   └── 002-cmd.sh
# │       └── build.sh
# ├── build-order.txt
# └── build.sh
# ```
