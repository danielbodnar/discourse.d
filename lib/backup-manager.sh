
#!/usr/bin/env bash

setup_backup_system() {
    log "Setting up backup system..."
    
    generate_backup_script
    generate_backup_service
    generate_backup_timer
    configure_discourse_backups
}

generate_backup_script() {
    cat > "${BASE_DIR}/rootfs/base/usr/lib/discourse/backup-manager" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# Source discourse environment
source /usr/lib/discourse/discourse-env

# Backup functions
create_backup() {
    log "Creating Discourse backup..."
    cd "${DISCOURSE_ROOT}"
    RAILS_ENV=production bundle exec rake backup:create
}

upload_to_s3() {
    local backup_file="$1"
    local s3_path="s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/$(basename "$backup_file")"
    
    if [ -n "${S3_ENDPOINT}" ]; then
        aws configure set default.s3.addressing_style path
        export AWS_ENDPOINT_URL="${S3_ENDPOINT}"
    fi
    
    log "Uploading backup to S3: ${s3_path}"
    aws s3 cp "$backup_file" "$s3_path" \
        --region "${S3_REGION}" \
        --no-progress
}

cleanup_old_backups() {
    log "Cleaning up old backups..."
    
    find "${DISCOURSE_DATA}/backups" -type f -mtime +${BACKUP_RETENTION_DAYS} -delete
    
    aws s3 ls "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/" \
        --region "${S3_REGION}" \
        | while read -r line; do
        timestamp=$(echo "$line" | awk '{print $1" "$2}')
        filename=$(echo "$line" | awk '{print $4}')
        backup_date=$(date -d "$timestamp" +%s)
        current_date=$(date +%s)
        days_old=$(( (current_date - backup_date) / 86400 ))
        
        if [ "$days_old" -gt "${BACKUP_RETENTION_DAYS}" ]; then
            aws s3 rm "s3://${S3_BACKUP_BUCKET}/${S3_BACKUP_PREFIX}/${filename}" \
                --region "${S3_REGION}"
        fi
    done
}

main() {
    create_backup
    latest_backup=$(find "${DISCOURSE_DATA}/backups" -type f -name "*.tar.gz" \
        -printf '%T@ %p\n' | sort -n | tail -1 | cut -f2- -d" ")
    
    if [ -n "$latest_backup" ]; then
        upload_to_s3 "$latest_backup"
    fi
    
    cleanup_old_backups
}

main "$@"
EOF

    chmod +x "${BASE_DIR}/rootfs/base/usr/lib/discourse/backup-manager"
}
generate_backup_service() {
    cat > "${BASE_DIR}/rootfs/base/etc/systemd/system/discourse-backup.service" << EOF
[Unit]
Description=Discourse Backup Service
After=discourse.service

[Service]
Type=oneshot
User=${DISCOURSE_USER}
Group=${DISCOURSE_GROUP}
Environment=RAILS_ENV=production
EnvironmentFile=/etc/discourse/backup-env
ExecStart=/usr/lib/discourse/backup-manager

# Security
NoNewPrivileges=yes
ProtectSystem=strict
ReadOnlyPaths=/
ReadWritePaths=${DISCOURSE_DATA}/backups
EOF
}

generate_backup_timer() {
    cat > "${BASE_DIR}/rootfs/base/etc/systemd/system/discourse-backup.timer" << EOF
[Unit]
Description=Discourse Backup Timer

[Timer]
OnCalendar=${BACKUP_SCHEDULE}
Persistent=true

[Install]
WantedBy=timers.target
EOF
}

configure_discourse_backups() {
    cat > "${BASE_DIR}/rootfs/base/etc/discourse/backup-env.template" << EOF
# S3 Backup Configuration
S3_BACKUP_BUCKET=
S3_BACKUP_PREFIX=backups
S3_REGION=us-east-1
#S3_ENDPOINT=
#S3_PATH_STYLE=false

# Backup Retention
BACKUP_RETENTION_DAYS=30
EOF
}
