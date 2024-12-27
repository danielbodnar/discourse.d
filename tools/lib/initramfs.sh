#!/bin/bash

setup_initramfs() {
    local mount_dir="$1"
    local modules="$2"
    local hooks="$3"
    local custom_initramfs="$4"

    if [ -n "$custom_initramfs" ]; then
        # Use custom initramfs
        cp "$custom_initramfs" "$mount_dir/boot/initrd.img"
    else
        # Configure and generate initramfs
        configure_initramfs "$mount_dir" "$modules" "$hooks"
        generate_initramfs "$mount_dir"
    fi
}

configure_initramfs() {
    local mount_dir="$1"
    local modules="$2"
    local hooks="$3"

    # Add custom modules
    if [ -n "$modules" ]; then
        echo "MODULES=\"$modules\"" >> "$mount_dir/etc/initramfs-tools/modules"
    fi

    # Add custom hooks
    if [ -n "$hooks" ]; then
        IFS=',' read -ra HOOK_ARRAY <<< "$hooks"
        for hook in "${HOOK_ARRAY[@]}"; do
            cp "$SCRIPT_DIR/hooks/$hook" "$mount_dir/etc/initramfs-tools/hooks/"
            chmod +x "$mount_dir/etc/initramfs-tools/hooks/$hook"
        done
    fi
}

generate_initramfs() {
    local mount_dir="$1"

    # Generate initramfs in chroot
    chroot "$mount_dir" update-initramfs -u -k all
}
