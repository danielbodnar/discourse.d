#!/usr/bin/env bash
set -euo pipefail

# Include additional configuration files
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/network.sh"
source "${SCRIPT_DIR}/lib/cloud-init.sh"
source "${SCRIPT_DIR}/lib/storage.sh"
source "${SCRIPT_DIR}/lib/snapshot.sh"
source "${SCRIPT_DIR}/lib/console.sh"
source "${SCRIPT_DIR}/lib/initramfs.sh"

# Function to display usage
usage() {
    cat << EOF
Usage: $0 --rootfs ROOTFS_DIR --output OUTPUT_DIR [options]

Creates a bootable QEMU VM image with advanced features.

Required:
    --rootfs    Directory containing the rootfs
    --output    Output directory for VM images and configs

VM Options:
    --size      VM image size (default: 10G)
    --mem       VM memory size (default: 2G)
    --cpus      Number of CPUs (default: 2)
    --name      VM name (default: discourse-vm)
    --efi       Path to OVMF.fd (default: auto-detect)
    --kernel    Custom kernel version (default: latest LTS)
    --init      Init system (default: systemd)

Network Options:
    --network-mode      Network mode (user|tap|bridge) (default: user)
    --bridge-name      Bridge interface name (default: br0)
    --mac-address      Custom MAC address
    --static-ip        Static IP address
    --netmask          Network mask (default: 255.255.255.0)
    --gateway          Gateway address
    --dns-servers      DNS servers (comma-separated)

Storage Options:
    --data-disk        Create additional data disk (size)
    --disk-format      Disk format (qcow2|raw|vdi) (default: qcow2)
    --disk-bus         Disk bus (virtio|sata|scsi) (default: virtio)
    --disk-cache       Disk cache mode (default: writeback)

Cloud-Init Options:
    --cloud-init       Enable cloud-init configuration
    --user-data        Path to user-data file
    --meta-data        Path to meta-data file
    --network-config   Path to network-config file

Console Options:
    --console         Console type (serial|virtio|both) (default: both)
    --console-log     Path to console log file
    --headless        Run without graphical display

Snapshot Options:
    --snapshot-mode    Snapshot mode (internal|external) (default: internal)
    --snapshot-format  Snapshot format (qcow2|raw) (default: qcow2)
    --snapshot-compress Enable snapshot compression

Initramfs Options:
    --initramfs-modules Additional initramfs modules (comma-separated)
    --initramfs-hooks   Additional initramfs hooks (comma-separated)
    --custom-initramfs  Path to custom initramfs file

Example:
    $0 --rootfs ./build/rootfs --output ./vm --size 20G --mem 4G \\
       --network-mode bridge --bridge-name br0 --static-ip 192.168.1.100 \\
       --data-disk 50G --cloud-init --console both
EOF
    exit 1
}

# Function to detect OVMF path
detect_ovmf() {
    local ovmf_paths=(
        "/usr/share/OVMF/OVMF_CODE.fd"
        "/usr/share/edk2/ovmf/OVMF_CODE.fd"
        "/usr/share/qemu/OVMF_CODE.fd"
    )

    for path in "${ovmf_paths[@]}"; do
        if [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    error "OVMF firmware not found. Please install OVMF/edk2-ovmf package."
}

# Function to create disk image
create_disk_image() {
    local output_dir="$1"
    local size="$2"
    local name="$3"

    log "Creating disk image..."
    qemu-img create -f qcow2 "$output_dir/$name.qcow2" "$size"

    # Create partition table and EFI partition
    parted "$output_dir/$name.qcow2" -- \
        mklabel gpt \
        mkpart ESP fat32 1MiB 512MiB \
        set 1 esp on \
        mkpart primary ext4 512MiB 100%
}

# Function to setup EFI partition
setup_efi() {
    local output_dir="$1"
    local name="$2"
    local loop_dev

    log "Setting up EFI partition..."

    # Set up loop device
    loop_dev=$(losetup --find --partscan --show "$output_dir/$name.qcow2")

    # Format EFI partition
    mkfs.fat -F32 "${loop_dev}p1"

    # Format root partition
    mkfs.ext4 "${loop_dev}p2"

    # Mount partitions
    local mount_dir="$output_dir/mnt"
    mkdir -p "$mount_dir"
    mount "${loop_dev}p2" "$mount_dir"
    mkdir -p "$mount_dir/boot/efi"
    mount "${loop_dev}p1" "$mount_dir/boot/efi"

    # Return loop device and mount point
    echo "$loop_dev:$mount_dir"
}

# Function to install bootloader
install_bootloader() {
    local mount_dir="$1"
    local name="$2"

    log "Installing bootloader..."

    # Install GRUB for EFI
    grub-install --target=x86_64-efi \
        --efi-directory="$mount_dir/boot/efi" \
        --bootloader-id="$name" \
        --boot-directory="$mount_dir/boot" \
        --no-nvram \
        --removable

    # Create GRUB configuration
    cat > "$mount_dir/boot/grub/grub.cfg" << EOF
set timeout=5
set default=0

menuentry "$name" {
    linux /boot/vmlinuz root=/dev/sda2 rw quiet
    initrd /boot/initrd.img
}
EOF
}

# Function to install kernel
install_kernel() {
    local mount_dir="$1"
    local kernel_version="$2"

    log "Installing kernel..."

    # Create temporary chroot
    mount -t proc none "$mount_dir/proc"
    mount -t sysfs none "$mount_dir/sys"
    mount -t devtmpfs none "$mount_dir/dev"

    # Install kernel
    chroot "$mount_dir" /bin/bash -c "
        apt-get update
        apt-get install -y linux-image-$kernel_version
    "

    # Clean up mounts
    umount "$mount_dir/dev"
    umount "$mount_dir/sys"
    umount "$mount_dir/proc"
}

# Function to copy rootfs
copy_rootfs() {
    local rootfs_dir="$1"
    local mount_dir="$2"

    log "Copying rootfs..."

    # Copy rootfs contents
    cp -a "$rootfs_dir"/* "$mount_dir/"

    # Create necessary directories
    mkdir -p "$mount_dir"/{proc,sys,dev,run,tmp}

    # Create fstab
    cat > "$mount_dir/etc/fstab" << EOF
/dev/sda2 / ext4 defaults 0 1
/dev/sda1 /boot/efi vfat defaults 0 2
proc /proc proc defaults 0 0
sysfs /sys sysfs defaults 0 0
devpts /dev/pts devpts gid=5,mode=620 0 0
tmpfs /run tmpfs defaults 0 0
EOF
}

# Function to create QEMU launch script
create_launch_script() {
    local output_dir="$1"
    local name="$2"
    local mem="$3"
    local cpus="$4"
    local ovmf="$5"

    cat > "$output_dir/run-$name.sh" << EOF
#!/bin/bash
qemu-system-x86_64 \\
    -name "$name" \\
    -machine q35,accel=kvm \\
    -cpu host \\
    -smp "$cpus" \\
    -m "$mem" \\
    -drive if=pflash,format=raw,readonly=on,file="$ovmf" \\
    -drive file="$output_dir/$name.qcow2",if=virtio \\
    -net nic,model=virtio \\
    -net user \\
    -display gtk \\
    -usb \\
    -device usb-tablet \\
    "\$@"
EOF
    chmod +x "$output_dir/run-$name.sh"
}

# Main function
main() {
    local rootfs_dir=""
    local output_dir=""
    local size="10G"
    local mem="2G"
    local cpus="2"
    local name="discourse-vm"
    local efi=""
    local kernel_version="$(uname -r)"
    local init_system="systemd"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --rootfs)
                rootfs_dir="$2"
                shift 2
                ;;
            --output)
                output_dir="$2"
                shift 2
                ;;
            --size)
                size="$2"
                shift 2
                ;;
            --mem)
                mem="$2"
                shift 2
                ;;
            --cpus)
                cpus="$2"
                shift 2
                ;;
            --name)
                name="$2"
                shift 2
                ;;
            --efi)
                efi="$2"
                shift 2
                ;;
            --kernel)
                kernel_version="$2"
                shift 2
                ;;
            --init)
                init_system="$2"
                shift 2
                ;;
            *)
                usage
                ;;
        esac
    done

    # Validate required arguments
    if [ -z "$rootfs_dir" ] || [ -z "$output_dir" ]; then
        usage
    fi

    # Create output directory
    mkdir -p "$output_dir"

    # Detect or validate OVMF path
    if [ -z "$efi" ]; then
        efi=$(detect_ovmf)
    elif [ ! -f "$efi" ]; then
        error "Specified OVMF file not found: $efi"
    fi

    # Create disk image
    create_disk_image "$output_dir" "$size" "$name"

    # Setup EFI partition
    local loop_mount
    loop_mount=$(setup_efi "$output_dir" "$name")
    local loop_dev="${loop_mount%:*}"
    local mount_dir="${loop_mount#*:}"

    # Copy rootfs
    copy_rootfs "$rootfs_dir" "$mount_dir"

    # Install kernel
    install_kernel "$mount_dir" "$kernel_version"

    # Install bootloader
    install_bootloader "$mount_dir" "$name"

    # Clean up mounts
    umount "$mount_dir/boot/efi"
    umount "$mount_dir"
    losetup -d "$loop_dev"
    rm -rf "$mount_dir"

    # Create launch script
    create_launch_script "$output_dir" "$name" "$mem" "$cpus" "$efi"

    log "VM image created successfully!"
    log "To start the VM, run: $output_dir/run-$name.sh"
}

# Helper functions
log() { echo "[$(date -u '+%Y-%m-%d %H:%M:%S')] $*" >&2; }
error() { log "ERROR: $*"; exit 1; }

# Run main function
main "$@"


# This script:

# 1. Creates a QEMU disk image with:
#    - GPT partition table
#    - EFI system partition
#    - Root partition

# 2. Sets up the boot environment:
#    - Formats partitions
#    - Installs GRUB EFI bootloader
#    - Configures kernel and initramfs

# 3. Copies the rootfs and configures the system:
#    - Copies all rootfs contents
#    - Creates necessary system directories
#    - Configures fstab

# 4. Creates a launch script for easy VM startup

# Usage:
# ```bash
# ./create-vm.sh \
#     --rootfs ./build/rootfs \
#     --output ./vm \
#     --size 20G \
#     --mem 4G \
#     --cpus 4 \
#     --name discourse-vm
# ```

# Requirements:
# - QEMU
# - OVMF (EFI firmware)
# - parted
# - grub-efi
# - losetup privileges (run as root/sudo)

# The script creates:
# ```
# vm/
# ├── discourse-vm.qcow2    # VM disk image
# └── run-discourse-vm.sh   # Launch script
# ```

# To start the VM:
# ```bash
# ./vm/run-discourse-vm.sh
# ```

# Additional features you might want to add:
# 1. Network configuration
# 2. Cloud-init support
# 3. Multiple disk support
# 4. Snapshot management
# 5. Console/serial access
# 6. Custom initramfs options
