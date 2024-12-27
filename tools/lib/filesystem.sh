# tools/lib/filesystem.sh
#!/usr/bin/env bash

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

    # Set cleanup trap
    trap_cleanup "$temp_container"

    # Create rootfs directory
    mkdir -p "$outdir/rootfs"

    # Export container filesystem
    debug "Exporting container filesystem"
    if ! docker export "$container" | tar -x -C "$outdir/rootfs"; then
        error "Failed to export container filesystem"
    fi

    # Create filesystem manifest
    create_filesystem_manifest "$outdir"

    # Cleanup temporary container handled by trap
}

# Function to create filesystem manifest
create_filesystem_manifest() {
    local outdir="$1"
    local manifest_file="$outdir/config/filesystem.manifest"

    debug "Creating filesystem manifest"

    {
        echo "# Filesystem manifest"
        echo "# Generated: $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
        echo ""
        echo "## Directory structure"
        (cd "$outdir/rootfs" && find . -type d -printf '%P\n' | sort) | sed 's/^/- /'
        echo ""
        echo "## Files"
        (cd "$outdir/rootfs" && find . -type f -printf '%P\n' | sort) | sed 's/^/- /'
    } > "$manifest_file"
}

# Function to handle filesystem permissions
fix_filesystem_permissions() {
    local outdir="$1"
    local rootfs_dir="$outdir/rootfs"

    debug "Fixing filesystem permissions"

    # Fix common permission issues
    find "$rootfs_dir" -type d -exec chmod 755 {} \;
    find "$rootfs_dir" -type f -executable -exec chmod 755 {} \;
    find "$rootfs_dir" -type f ! -executable -exec chmod 644 {} \;
}

# Function to create necessary directories
create_required_directories() {
    local rootfs_dir="$1"

    debug "Creating required directories"

    local required_dirs=(
        "dev"
        "proc"
        "sys"
        "tmp"
        "run"
        "var/log"
        "var/tmp"
    )

    for dir in "${required_dirs[@]}"; do
        mkdir -p "$rootfs_dir/$dir"
    done
}
