#!/bin/bash

setup_networking() {
    local mode="$1"
    local bridge="$2"
    local mac="$3"
    local ip="$4"
    local netmask="$5"
    local gateway="$6"
    local dns="$7"
    local mount_dir="$8"

    case "$mode" in
        user)
            # Default QEMU user networking
            QEMU_NET_OPTS="-net nic,model=virtio -net user"
            ;;
        tap)
            # TAP interface networking
            QEMU_NET_OPTS="-netdev tap,id=net0,ifname=tap0,script=no,downscript=no \
                          -device virtio-net-pci,netdev=net0,mac=$mac"
            setup_tap_interface
            ;;
        bridge)
            # Bridge networking
            QEMU_NET_OPTS="-netdev bridge,id=net0,br=$bridge \
                          -device virtio-net-pci,netdev=net0,mac=$mac"
            setup_bridge_interface "$bridge"
            ;;
    esac

    # Configure network in VM
    if [ -n "$ip" ]; then
        configure_static_networking "$mount_dir" "$ip" "$netmask" "$gateway" "$dns"
    fi
}

setup_tap_interface() {
    # Create and configure TAP interface
    ip tuntap add tap0 mode tap user "$SUDO_USER"
    ip link set tap0 up
}

setup_bridge_interface() {
    local bridge="$1"

    # Create bridge if it doesn't exist
    if ! ip link show "$bridge" >/dev/null 2>&1; then
        ip link add name "$bridge" type bridge
        ip link set "$bridge" up
    fi
}

configure_static_networking() {
    local mount_dir="$1"
    local ip="$2"
    local netmask="$3"
    local gateway="$4"
    local dns="$5"

    # Configure netplan for Ubuntu/Debian
    cat > "$mount_dir/etc/netplan/01-netcfg.yaml" << EOF
network:
  version: 2
  ethernets:
    eth0:
      addresses: [$ip/$netmask]
      gateway4: $gateway
      nameservers:
        addresses: [${dns//,/ }]
EOF

    # Configure NetworkManager for other distributions
    cat > "$mount_dir/etc/NetworkManager/system-connections/eth0.nmconnection" << EOF
[connection]
id=eth0
type=ethernet
interface-name=eth0

[ipv4]
method=manual
addresses=$ip/$netmask
gateway=$gateway
dns=${dns//,/;}
EOF
}
