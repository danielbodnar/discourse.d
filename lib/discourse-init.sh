
#!/usr/bin/env bash

setup_discourse_environment() {
    log "Setting up Discourse environment..."
    
    generate_discourse_env
    generate_discourse_config
    generate_discourse_defaults
}

generate_discourse_env() {
    cat > "${BASE_DIR}/rootfs/base/usr/lib/discourse/discourse-env" << 'EOF'
#!/usr/bin/env bash

# Load base configuration
source /etc/discourse/discourse.conf

# Load all configuration overrides in order
if [ -d /etc/discourse/discourse.conf.d ]; then
    for conf in /etc/discourse/discourse.conf.d/*.conf; do
        [ -f "$conf" ] && source "$conf"
    done
fi

# Set development defaults if not configured
: "${DISCOURSE_HOSTNAME:=0.0.0.0}"
: "${DISCOURSE_PORT:=3000}"
: "${DISCOURSE_DB_HOST:=0.0.0.0}"
: "${DISCOURSE_DB_PORT:=5432}"
: "${DISCOURSE_REDIS_HOST:=0.0.0.0}"
: "${DISCOURSE_REDIS_PORT:=6379}"
: "${RAILS_ENV:=production}"
EOF

    chmod +x "${BASE_DIR}/rootfs/base/usr/lib/discourse/discourse-env"
}

generate_discourse_config() {
    cat > "${BASE_DIR}/rootfs/base/etc/discourse/discourse.conf" << 'EOF'
# Discourse Configuration File
# See: https://github.com/discourse/discourse/blob/main/config/discourse_defaults.conf

# Database Configuration
db_pool = 12
db_timeout = 5000
db_connect_timeout = 5000
db_socket = 
db_host = ${DISCOURSE_DB_HOST}
db_port = ${DISCOURSE_DB_PORT}
db_name = ${DISCOURSE_DB_NAME}
db_username = ${DISCOURSE_DB_USER}
db_password = ${DISCOURSE_DB_PASSWORD}

# Redis Configuration
redis_host = ${DISCOURSE_REDIS_HOST}
redis_port = ${DISCOURSE_REDIS_PORT}
redis_db = 0
redis_password = ${DISCOURSE_REDIS_PASSWORD}

# Email Configuration
smtp_address = ${DISCOURSE_SMTP_HOST}
smtp_port = ${DISCOURSE_SMTP_PORT}
smtp_domain = ${DISCOURSE_SMTP_DOMAIN}
smtp_user_name = ${DISCOURSE_SMTP_USER}
smtp_password = ${DISCOURSE_SMTP_PASSWORD}
smtp_enable_start_tls = true
smtp_authentication = login
smtp_openssl_verify_mode = none

# CDN Configuration
cdn_url = ${DISCOURSE_CDN_URL}
s3_backup_bucket = ${S3_BACKUP_BUCKET}
s3_backup_prefix = ${S3_BACKUP_PREFIX}
s3_region = ${S3_REGION}
EOF
}

generate_discourse_defaults() {
    cat > "${BASE_DIR}/rootfs/base/etc/discourse/discourse.conf.d/10-defaults.conf" << 'EOF'
# Default development settings
DISCOURSE_HOSTNAME=0.0.0.0
DISCOURSE_PORT=3000
DISCOURSE_DB_HOST=0.0.0.0
DISCOURSE_DB_PORT=5432
DISCOURSE_REDIS_HOST=0.0.0.0
DISCOURSE_REDIS_PORT=6379
RAILS_ENV=production
EOF
}
