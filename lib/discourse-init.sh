#!/usr/bin/env bash

# Load base configuration
source /etc/discourse/discourse.conf

# Load all configuration overrides in order
if [ -d /etc/discourse/discourse.conf.d ]; then
    for conf in /etc/discourse/discourse.conf.d/*.conf; do
        [ -f "$conf" ] && source "$conf"
    done
fi

# Initialize directories
for dir in "${DISCOURSE_PERSISTENT_DIRS[@]}"; do
    mkdir -p "$dir"
    chown -R "$DISCOURSE_USER:$DISCOURSE_GROUP" "$dir"
done

# Configure PostgreSQL connection
cat > "$DISCOURSE_ROOT/config/database.yml" << EOF
production:
  adapter: postgresql
  database: ${POSTGRES_DB}
  username: ${POSTGRES_USER}
  password: ${POSTGRES_PASSWORD}
  host: ${POSTGRES_HOST}
  pool: ${POSTGRES_POOL_SIZE:-5}
EOF

# Configure Redis connection
cat > "$DISCOURSE_ROOT/config/redis.yml" << EOF
defaults: &defaults
  host: ${REDIS_HOST}
  port: ${REDIS_PORT}
  password: ${REDIS_PASSWORD}
  db: 0
  cache_db: 2

production:
  <<: *defaults
EOF

# Configure backup settings
cat > "$DISCOURSE_ROOT/config/backups.yml" << EOF
production:
  backup_provider: ${BACKUP_PROVIDER:-local}
  s3_backup_bucket: ${S3_BACKUP_BUCKET:-}
  s3_backup_region: ${S3_REGION:-us-east-1}
  s3_backup_path: ${S3_PATH:-backups}
EOF

# Set up assets
RAILS_ENV=production bundle exec rake assets:precompile

# Run migrations
RAILS_ENV=production bundle exec rake db:migrate
