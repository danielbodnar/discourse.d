#!/bin/bash

setup_storage() {
    local output_dir="$1"
    local name="$2"
    local data_disk_size="$3"
    local disk_format="$4"
    local disk_bus="$5"
    local disk_cache="$6"

    # Create data disk if specified
    if [ -n "$data_disk_size" ]; then
        create_data_disk "$output_dir" "$name" "$data_disk_size" "$disk_format"
        configure_data_disk_mount "$mount_dir"
    fi

    # Configure disk options
    QEMU_DISK_OPTS="-drive file=$output_dir/$name.qcow2,if=$disk_bus,cache=$disk_cache,format=$disk_format"

    if [ -n "$data_disk_size" ]; then
        QEMU_DISK_OPTS="$QEMU_DISK_OPTS -drive file=$output_dir/${name}_data.qcow2,if=$disk_bus,cache=$disk_cache,format=$disk_format"
    fi
}

create_data_disk() {
    local output_dir="$1"
    local name="$2"
    local size="$3"
    local format="$4"

    qemu-img create -f "$format" "$output_dir/${name}_data.qcow2" "$size"
}

configure_data_disk_mount() {
    local mount_dir="$1"

    # Add data disk to fstab
    echo "/dev/sdb1 /data ext4 defaults 0 2" >> "$mount_dir/etc/fstab"

    # Create mount point
    mkdir -p "$mount_dir/data"
}
