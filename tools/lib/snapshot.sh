#!/bin/bash

setup_snapshots() {
    local output_dir="$1"
    local name="$2"
    local mode="$3"
    local format="$4"
    local compress="$5"

    # Create snapshots directory
    mkdir -p "$output_dir/snapshots"

    # Create snapshot management scripts
    create_snapshot_scripts "$output_dir" "$name" "$mode" "$format" "$compress"
}

create_snapshot_scripts() {
    local output_dir="$1"
    local name="$2"
    local mode="$3"
    local format="$4"
    local compress="$5"

    # Create snapshot creation script
    cat > "$output_dir/create-snapshot.sh" << EOF
#!/bin/bash
set -euo pipefail

snapshot_name="\${1:-snapshot-\$(date +%Y%m%d-%H%M%S)}"
snapshot_dir="$output_dir/snapshots/\$snapshot_name"

mkdir -p "\$snapshot_dir"

if [ "$mode" = "internal" ]; then
    qemu-img snapshot -c "\$snapshot_name" "$output_dir/$name.qcow2"
else
    qemu-img create -f "$format" -b "$output_dir/$name.qcow2" -F qcow2 "\$snapshot_dir/disk.${format}"
    ${compress:+gzip "\$snapshot_dir/disk.${format}"}
fi

echo "Snapshot \$snapshot_name created"
EOF
    chmod +x "$output_dir/create-snapshot.sh"

    # Create snapshot restore script
    cat > "$output_dir/restore-snapshot.sh" << EOF
#!/bin/bash
set -euo pipefail

snapshot_name="\$1"

if [ "$mode" = "internal" ]; then
    qemu-img snapshot -a "\$snapshot_name" "$output_dir/$name.qcow2"
else
    snapshot_dir="$output_dir/snapshots/\$snapshot_name"
    ${compress:+gunzip "\$snapshot_dir/disk.${format}.gz"}
    cp "\$snapshot_dir/disk.${format}" "$output_dir/$name.qcow2"
fi

echo "Snapshot \$snapshot_name restored"
EOF
    chmod +x "$output_dir/restore-snapshot.sh"
}
