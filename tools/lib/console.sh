#!/bin/bash

setup_console() {
    local type="$1"
    local log_file="$2"
    local headless="$3"

    case "$type" in
        serial)
            QEMU_CONSOLE_OPTS="-nographic -serial stdio"
            configure_serial_console "$mount_dir"
            ;;
        virtio)
            QEMU_CONSOLE_OPTS="-device virtio-serial -chardev stdio,id=virtiocon0 -device virtconsole,chardev=virtiocon0"
            configure_virtio_console "$mount_dir"
            ;;
        both)
            QEMU_CONSOLE_OPTS="-serial stdio -device virtio-serial -chardev stdio,id=virtiocon0 -device virtconsole,chardev=virtiocon0"
            configure_serial_console "$mount_dir"
            configure_virtio_console "$mount_dir"
            ;;
    esac

    if [ -n "$log_file" ]; then
        QEMU_CONSOLE_OPTS="$QEMU_CONSOLE_OPTS -chardev file,id=log,path=$log_file -device virtio-serial -device virtserialport,chardev=log"
    fi

    if [ "$headless" = "true" ]; then
        QEMU_CONSOLE_OPTS="$QEMU_CONSOLE_OPTS -display none"
    fi
}

configure_serial_console() {
    local mount_dir="$1"

    # Configure GRUB for serial console
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=ttyS0,115200n8 /' "$mount_dir/etc/default/grub"

    # Enable serial getty
    ln -sf /lib/systemd/system/serial-getty@.service \
        "$mount_dir/etc/systemd/system/getty.target.wants/serial-getty@ttyS0.service"
}

configure_virtio_console() {
    local mount_dir="$1"

    # Configure GRUB for virtio console
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="console=tty0 console=hvc0 /' "$mount_dir/etc/default/grub"

    # Enable virtio getty
    ln -sf /lib/systemd/system/serial-getty@.service \
        "$mount_dir/etc/systemd/system/getty.target.wants/serial-getty@hvc0.service"
}
