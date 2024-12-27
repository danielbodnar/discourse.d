# QEMU VM Creation Tool Documentation

## Overview
The VM Creation Tool generates bootable QEMU virtual machines from container rootfs directories. It supports EFI boot, multiple storage configurations, networking options, and various system optimizations.

## Features
- EFI boot support
- Multiple disk configurations
- Network configuration
- Cloud-init integration
- Snapshot management
- Console/serial access
- Custom initramfs support
- Automated VM provisioning

## Requirements
- QEMU
- OVMF (EFI firmware)
- Cloud-init
- Linux kernel with KVM support
- Sufficient disk space
- Root/sudo access

## Installation
```bash
# Install dependencies
apt-get install qemu-system-x86 ovmf cloud-init

# Install script
curl -o create-vm https://raw.githubusercontent.com/your-repo/create-vm.sh
chmod +x create-vm
sudo mv create-vm /usr/local/bin/
```

## Basic Usage
```bash
create-vm \
    --rootfs ./rootfs \
    --output ./vm \
    --size 20G \
    --mem 4G \
    --cpus 2
```

## Command Line Options

### Required Arguments
- `--rootfs`: Source rootfs directory
- `--output`: Output directory for VM files

### Optional Arguments
```bash
# System Resources
--size SIZE       # Disk size (default: 10G)
--mem MEMORY      # RAM allocation (default: 2G)
--cpus COUNT      # CPU cores (default: 2)

# Boot Options
--efi PATH        # Custom OVMF path
--kernel VERSION  # Specific kernel version
--init SYSTEM     # Init system type

# Network Options
--network MODE    # Network mode (user/tap/bridge)
--bridge NAME     # Bridge interface name
--mac ADDRESS     # Custom MAC address

# Storage Options
--disk-format    # Disk image format (qcow2/raw)
--data-disk      # Additional data disk size

# Advanced Features
--cloud-init     # Enable cloud-init
--console TYPE   # Console type (serial/virtio)
--snapshot MODE  # Snapshot capability
```

## Directory Structure
```plaintext
vm/
├── disk/
│   ├── system.qcow2
│   └── data.qcow2
├── efi/
│   └── OVMF_CODE.fd
├── config/
│   ├── cloud-init/
│   └── network/
├── snapshots/
└── run.sh
```

## Configuration Files

### 1. VM Configuration
```yaml
# config/vm.yaml
system:
  memory: 4G
  cpus: 2
  machine: q35
  accel: kvm

storage:
  system:
    size: 20G
    format: qcow2
  data:
    size: 50G
    format: qcow2

network:
  type: bridge
  bridge: br0
  mac: "52:54:00:12:34:56"
```

### 2. Cloud-Init Configuration
```yaml
# config/cloud-init/user-data
#cloud-config
users:
  - name: admin
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
      - ssh-rsa AAAA...

packages:
  - qemu-guest-agent
  - cloud-init
```

## Features in Detail

### 1. EFI Boot Setup
```bash
# Setup EFI partition
create_efi_partition() {
    parted "$disk" -- \
        mklabel gpt \
        mkpart ESP fat32 1MiB 512MiB \
        set 1 esp on
}
```

### 2. Storage Management
```bash
# Create and format disks
setup_storage() {
    qemu-img create -f qcow2 "$disk" "$size"
    mkfs.ext4 "${disk}p2"
}
```

### 3. Network Configuration
```bash
# Configure networking
setup_networking() {
    case "$network_mode" in
        bridge)
            setup_bridge_networking
            ;;
        tap)
            setup_tap_networking
            ;;
    esac
}
```

### 4. Snapshot Management
```bash
# Create snapshot
create_snapshot() {
    qemu-img snapshot -c "$snapshot_name" "$disk"
}

# Restore snapshot
restore_snapshot() {
    qemu-img snapshot -a "$snapshot_name" "$disk"
}
```

## Integration Examples

### 1. Automated VM Creation
```bash
#!/bin/bash
# create-test-vm.sh

create-vm \
    --rootfs ./rootfs \
    --output ./test-vm \
    --size 20G \
    --mem 4G \
    --cpus 2 \
    --network bridge \
    --cloud-init
```

### 2. CI/CD Pipeline
```yaml
name: VM Tests
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Create VM
        run: |
          ./create-vm \
            --rootfs ./rootfs \
            --output ./vm \
            --size 20G
      - name: Run Tests
        run: ./vm/run-tests.sh
```

## Advanced Usage

### 1. Custom Kernel
```bash
create-vm \
    --rootfs ./rootfs \
    --output ./vm \
    --kernel 5.15.0 \
    --initramfs ./custom-initramfs.img
```

### 2. Multiple Disks
```bash
create-vm \
    --rootfs ./rootfs \
    --output ./vm \
    --size 20G \
    --data-disk 50G
```

### 3. Network Bridge
```bash
create-vm \
    --rootfs ./rootfs \
    --output ./vm \
    --network bridge \
    --bridge br0
```

## Troubleshooting

### Common Issues

1. KVM Access
```bash
# Add user to kvm group
sudo usermod -aG kvm $USER
```

2. Bridge Network
```bash
# Enable bridge network
sudo modprobe bridge
sudo sysctl net.bridge.bridge-nf-call-iptables=0
```

3. Disk Space
```bash
# Check available space
df -h
# Clean up old images
./cleanup-images.sh
```

## Performance Optimization

### 1. CPU Configuration
```bash
# Enable CPU passthrough
--cpu host
```

### 2. Disk I/O
```bash
# Enable disk cache
--drive cache=writeback
```

### 3. Network Performance
```bash
# Enable vhost networking
--netdev tap,vhost=on
```

## Security Considerations

### 1. Secure Boot
```bash
# Enable Secure Boot
--secure-boot
```

### 2. Disk Encryption
```bash
# Enable LUKS encryption
setup_disk_encryption() {
    cryptsetup luksFormat "$disk"
}
```

### 3. Network Security
```bash
# Enable network isolation
--network none
```

## Monitoring and Logging

### 1. Console Logs
```bash
# Enable console logging
--serial file:vm.log
```

### 2. Performance Metrics
```bash
# Enable performance monitoring
--monitor unix:monitor.sock,server,nowait
```
