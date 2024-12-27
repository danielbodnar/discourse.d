
#!/usr/bin/env bash
set -euo pipefail

# Source configuration
source "$(dirname "${BASH_SOURCE[0]}")/00-config.sh"

create_directory_structure() {
    log "Creating directory structure..."
    
    # Create base filesystem structure
    mkdir -p "${BASE_DIR}/rootfs/base"/{etc,usr,var}
    mkdir -p "${BASE_DIR}/rootfs/base/usr"/{bin,lib,share}
    mkdir -p "${BASE_DIR}/rootfs/base/etc"/{systemd,nginx}
    mkdir -p "${BASE_DIR}/rootfs/base/var"/{log,run}/discourse

    # Create distribution-specific directories
    for dist in "${DISTRIBUTIONS[@]}"; do
        mkdir -p "${BASE_DIR}/rootfs/${dist}"
    done

    # Create Discourse specific directories
    mkdir -p "${BASE_DIR}/rootfs/base${DISCOURSE_ROOT}"
    mkdir -p "${BASE_DIR}/rootfs/base${DISCOURSE_HOME}"
    mkdir -p "${BASE_DIR}/rootfs/base${DISCOURSE_DATA}"
    
    # Create build directories
    mkdir -p "${BASE_DIR}/build"/{gems,assets,plugins}

    # Create volume mount points
    for volume in "${DISCOURSE_VOLUMES[@]}"; do
        IFS=':' read -r name path <<< "$volume"
        mkdir -p "${BASE_DIR}/rootfs/base${path}"
    done
    
    # Set up correct permissions
    chown -R root:root "${BASE_DIR}/rootfs"
    chmod 755 "${BASE_DIR}/rootfs"

    # Set up Discourse user home
    chown -R "${DISCOURSE_UID}:${DISCOURSE_GID}" \
        "${BASE_DIR}/rootfs/base${DISCOURSE_HOME}"
    
    # Set up Discourse application directory
    chown -R "${DISCOURSE_UID}:${DISCOURSE_GID}" \
        "${BASE_DIR}/rootfs/base${DISCOURSE_ROOT}"
    
    success "Directory structure created"
}
