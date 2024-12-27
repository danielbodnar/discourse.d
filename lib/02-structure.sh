
#!/usr/bin/env bash

create_directory_structure() {
    log "Creating directory structure..."
    
    mkdir -p "${BASE_DIR}/rootfs/base"{etc,usr,var}
    mkdir -p "${BASE_DIR}/rootfs/base/usr"{bin,lib,share}
    mkdir -p "${BASE_DIR}/rootfs/base/etc"{discourse,nginx}
    mkdir -p "${BASE_DIR}/rootfs/base/var"{log,run}/discourse
    
    chown -R root:root "${BASE_DIR}/rootfs"
    chmod 755 "${BASE_DIR}/rootfs"
}
