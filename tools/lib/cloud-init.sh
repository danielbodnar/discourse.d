#!/bin/bash

setup_cloud_init() {
    local mount_dir="$1"
    local user_data="$2"
    local meta_data="$3"
    local network_config="$4"

    # Install cloud-init package
    chroot "$mount_dir" apt-get install -y cloud-init

    # Create cloud-init directory
    mkdir -p "$mount_dir/var/lib/cloud/seed/nocloud-net"

    # Copy cloud-init configurations
    if [ -f "$user_data" ]; then
        cp "$user_data" "$mount_dir/var/lib/cloud/seed/nocloud-net/user-data"
    else
        create_default_user_data "$mount_dir"
    fi

    if [ -f "$meta_data" ]; then
        cp "$meta_data" "$mount_dir/var/lib/cloud/seed/nocloud-net/meta-data"
    else
        create_default_meta_data "$mount_dir"
    fi

    if [ -f "$network_config" ]; then
        cp "$network_config" "$mount_dir/var/lib/cloud/seed/nocloud-net/network-config"
    fi
}

create_default_user_data() {
    local mount_dir="$1"

    cat > "$mount_dir/var/lib/cloud/seed/nocloud-net/user-data" << EOF
#cloud-config
hostname: discourse-vm
manage_etc_hosts: true
users:
  - name: discourse
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
    ssh_authorized_keys:
      - $(cat ~/.ssh/id_rsa.pub 2>/dev/null || echo '')
package_update: true
package_upgrade: true
EOF
}

create_default_meta_data() {
    local mount_dir="$1"

    cat > "$mount_dir/var/lib/cloud/seed/nocloud-net/meta-data" << EOF
instance-id: discourse-vm
local-hostname: discourse-vm
EOF
}
