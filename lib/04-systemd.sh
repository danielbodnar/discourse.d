
#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/00-config.sh"

generate_systemd_service() {
    log "Generating SystemD service configurations..."

    generate_main_service
    generate_socket_unit
    generate_slice_unit
}

generate_main_service() {
    cat > "${BASE_DIR}/rootfs/base/usr/lib/systemd/system/discourse.service" << EOF
[Unit]
Description=Discourse Discussion Platform
After=network.target postgresql.service redis.service
Requires=discourse.socket

[Service]
Type=notify
User=${DISCOURSE_USER}
Group=${DISCOURSE_GROUP}
Slice=discourse.slice

Environment=RAILS_ENV=production
EnvironmentFile=/etc/discourse/discourse.conf
EnvironmentFile=/etc/discourse/discourse.conf.d/*.conf

ExecStart=/usr/bin/discourse-server
ExecReload=/bin/kill -USR2 \$MAINPID
Restart=always
RestartSec=10

# Security
NoNewPrivileges=yes
ProtectSystem=strict
ProtectHome=yes
PrivateTmp=yes
PrivateDevices=yes
ReadOnlyPaths=/

[Install]
WantedBy=multi-user.target
EOF
}

generate_socket_unit() {
    cat > "${BASE_DIR}/rootfs/base/usr/lib/systemd/system/discourse.socket" << EOF
[Unit]
Description=Discourse Socket

[Socket]
ListenStream=/run/discourse/discourse.sock
SocketUser=${DISCOURSE_USER}
SocketGroup=${DISCOURSE_GROUP}
SocketMode=0660

[Install]
WantedBy=sockets.target
EOF
}

generate_slice_unit() {
    cat > "${BASE_DIR}/rootfs/base/usr/lib/systemd/system/discourse.slice" << EOF
[Unit]
Description=Discourse Resource Control Slice
Before=slices.target

[Slice]
CPUWeight=${MAX_CPU_WEIGHT}
MemoryHigh=2G
MemoryMax=${MAX_MEMORY}
TasksMax=${MAX_TASKS}

[Install]
WantedBy=multi-user.target
EOF
}
