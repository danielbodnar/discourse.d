#!/usr/bin/env bash
set -euo pipefail

# This script:

# 1. Accepts `--from`, `--to`, and `--outdir` parameters
# 2. Pulls both images and creates temporary containers
# 3. Exports their filesystems
# 4. Uses `rsync` to create a differential rootfs containing only the changes
# 5. Extracts non-filesystem commands (ENV, EXPOSE, VOLUME, etc.) from the target image
# 6. Creates a new Dockerfile that:
#    - Uses the "from" image as base
#    - Copies the differential rootfs
#    - Adds all non-filesystem commands from the target image

# Usage example:
# ```bash
# chmod +x create-diff-rootfs.sh
# ./create-diff-rootfs.sh \
#     --from bitnami/discourse:3.2.1 \
#     --to discourse/base:3.2.1 \
#     --outdir ./migration
# ```

# The script will create:
# - `./migration/rootfs/` - containing only the files that differ
# - `./migration/Dockerfile` - using the source image and applying the changes

# You can then build the new image with:
# ```bash
# docker build -t new-discourse ./migration
# ```

# The resulting image should be functionally equivalent to the target image but built on top of the source image.


# Function to display usage
usage() {
    cat << EOF
Usage: $0 --from FROM_IMAGE --to TO_IMAGE --outdir OUTPUT_DIR

Creates a differential rootfs and Dockerfile between two container images.

Options:
    --from      Source container image
    --to        Target container image
    --outdir    Output directory for rootfs and Dockerfile

Example:
    $0 --from bitnami/discourse:3.2.1 --to discourse/base:3.2.1 --outdir ./migration
EOF
    exit 1
}

# Function to extract image config
get_image_config() {
    local image="$1"
    docker pull "$image" >/dev/null
    local config=$(docker inspect "$image" | jq -r '.[0].Config')
    echo "$config"
}

# Function to extract non-fs commands from image
get_non_fs_commands() {
    local config="$1"
    local commands=""

    # Extract exposed ports
    local exposed_ports=$(echo "$config" | jq -r '.ExposedPorts | keys[]' 2>/dev/null || echo "")
    if [ -n "$exposed_ports" ]; then
        for port in $exposed_ports; do
            commands+="EXPOSE ${port%/*}\n"
        done
    fi

    # Extract environment variables
    local env_vars=$(echo "$config" | jq -r '.Env[]' 2>/dev/null || echo "")
    if [ -n "$env_vars" ]; then
        commands+="ENV \\\\\n"
        local first=true
        while IFS= read -r env; do
            if [ "$first" = true ]; then
                commands+="    $env \\\\\n"
                first=false
            else
                commands+="    $env \\\\\n"
            fi
        done <<< "$env_vars"
        commands="${commands%\\\\\n}"
        commands+="\n"
    fi

    # Extract volumes
    local volumes=$(echo "$config" | jq -r '.Volumes | keys[]' 2>/dev/null || echo "")
    if [ -n "$volumes" ]; then
        commands+="VOLUME ["
        local first=true
        while IFS= read -r volume; do
            if [ "$first" = true ]; then
                commands+="\"$volume\""
                first=false
            else
                commands+=", \"$volume\""
            fi
        done <<< "$volumes"
        commands+="]\n"
    fi

    # Extract entrypoint
    local entrypoint=$(echo "$config" | jq -r '.Entrypoint[]' 2>/dev/null || echo "")
    if [ -n "$entrypoint" ]; then
        commands+="ENTRYPOINT ["
        local first=true
        while IFS= read -r entry; do
            if [ "$first" = true ]; then
                commands+="\"$entry\""
                first=false
            else
                commands+=", \"$entry\""
            fi
        done <<< "$entrypoint"
        commands+="]\n"
    fi

    # Extract cmd
    local cmd=$(echo "$config" | jq -r '.Cmd[]' 2>/dev/null || echo "")
    if [ -n "$cmd" ]; then
        commands+="CMD ["
        local first=true
        while IFS= read -r command; do
            if [ "$first" = true ]; then
                commands+="\"$command\""
                first=false
            else
                commands+=", \"$command\""
            fi
        done <<< "$cmd"
        commands+="]\n"
    fi

    # Extract working directory
    local workdir=$(echo "$config" | jq -r '.WorkingDir' 2>/dev/null || echo "")
    if [ -n "$workdir" ] && [ "$workdir" != "/" ]; then
        commands+="WORKDIR $workdir\n"
    fi

    echo -e "$commands"
}

# Function to create differential rootfs
create_diff_rootfs() {
    local from_image="$1"
    local to_image="$2"
    local outdir="$3"

    # Create temporary containers
    local from_container=$(docker create "$from_image")
    local to_container=$(docker create "$to_image")

    # Create temporary directories
    local tempdir=$(mktemp -d)
    mkdir -p "$tempdir/from" "$tempdir/to" "$outdir/rootfs"

    # Export container filesystems
    docker export "$from_container" | tar -xf - -C "$tempdir/from"
    docker export "$to_container" | tar -xf - -C "$tempdir/to"

    # Clean up containers
    docker rm "$from_container" "$to_container"

    # Generate diff using rsync
    rsync -rcm --compare-dest="$tempdir/from/" "$tempdir/to/" "$outdir/rootfs/"

    # Clean up temporary directories
    rm -rf "$tempdir"
}

# Function to create Dockerfile
create_dockerfile() {
    local from_image="$1"
    local to_config="$2"
    local outdir="$3"

    # Create Dockerfile
    cat > "$outdir/Dockerfile" << EOF
# Generated by $(basename "$0") on $(date -u)
FROM $from_image

# Copy differential rootfs
COPY rootfs /

# Additional commands from target image
$(get_non_fs_commands "$to_config")
EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --from)
            from_image="$2"
            shift 2
            ;;
        --to)
            to_image="$2"
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
if [ -z "${from_image:-}" ] || [ -z "${to_image:-}" ] || [ -z "${outdir:-}" ]; then
    usage
fi

# Create output directory
mkdir -p "$outdir"

# Get image configs
to_config=$(get_image_config "$to_image")

# Create differential rootfs
echo "Creating differential rootfs..."
create_diff_rootfs "$from_image" "$to_image" "$outdir"

# Create Dockerfile
echo "Creating Dockerfile..."
create_dockerfile "$from_image" "$to_config" "$outdir"

echo "Done! Output files are in $outdir"
echo "You can build the new image with: docker build -t new-image $outdir"
