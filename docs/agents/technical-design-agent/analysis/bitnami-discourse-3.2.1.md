# Bitnami Discourse 3.2.1 Container Analysis

## Base Image: minideb
Minideb is Bitnami's minimal Debian-based image optimized for containers.

### Key characteristics:
- Based on Debian Bookworm
- Minimal package set
- Custom package manager wrapper (`install_packages`)
- Built-in security optimizations

## Layer Analysis

### 1. Base System Setup
```dockerfile
FROM bitnami/minideb:bookworm

# Install required packages
RUN install_packages ca-certificates curl libaudit1 libbrotli1 libbsd0 \
    libcap-ng0 libcom-err2 libcrypt1 libcurl4 libexpat1 libffi8 libgcc-s1 \
    libgcrypt20 libgmp10 libgnutls30 libgpg-error0 libgssapi-krb5-2 \
    libhogweed6 libidn2-0 libk5crypto3 libkeyutils1 libkrb5-3 libkrb5support0 \
    libldap-2.5-0 liblzma5 libmd0 libnettle8 libnghttp2-14 libp11-kit0 \
    libpam0g libpcre2-8-0 libpsl5 librtmp1 libsasl2-2 libssh2-1 \
    libssl3 libstdc++6 libtasn1-6 libunistring2 libxcrypt1 procps \
    zlib1g
```

### 2. Ruby Environment
```dockerfile
ENV RUBY_VERSION=3.2.2
RUN curl -LO "https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-$RUBY_VERSION.tar.gz" && \
    tar -xzf ruby-$RUBY_VERSION.tar.gz && \
    cd ruby-$RUBY_VERSION && \
    ./configure --disable-install-doc && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf ruby-$RUBY_VERSION*
```

### 3. Node.js Setup
```dockerfile
ENV NODE_VERSION=18.18.0
RUN curl -fsSLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" && \
    tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 && \
    rm "node-v$NODE_VERSION-linux-x64.tar.xz"
```

### 4. Discourse User Setup
```bash
#!/bin/bash
# Component: create-discourse-user.sh

# Create discourse group
groupadd -r discourse

# Create discourse user
useradd -r -g discourse -d /home/discourse -s /sbin/nologin discourse

# Create required directories
mkdir -p /home/discourse \
    /opt/bitnami/discourse \
    /opt/bitnami/discourse/tmp/pids \
    /opt/bitnami/discourse/tmp/sockets

# Set permissions
chown -R discourse:discourse \
    /home/discourse \
    /opt/bitnami/discourse
```

### 5. Discourse Installation
```bash
#!/bin/bash
# Component: install-discourse.sh

cd /opt/bitnami/discourse

# Clone Discourse
git clone --branch v3.2.1 https://github.com/discourse/discourse.git .

# Install dependencies
bundle install --deployment --without development test
yarn install --production

# Precompile assets
RAILS_ENV=production bundle exec rake assets:precompile
```

### 6. Configuration Files
#### 6.1 discourse.conf
```ruby
# /opt/bitnami/discourse/config/discourse.conf
db_host = ENV['DISCOURSE_DATABASE_HOST']
db_port = ENV['DISCOURSE_DATABASE_PORT']
db_name = ENV['DISCOURSE_DATABASE_NAME']
db_username = ENV['DISCOURSE_DATABASE_USERNAME']
db_password = ENV['DISCOURSE_DATABASE_PASSWORD']

redis_host = ENV['DISCOURSE_REDIS_HOST']
redis_port = ENV['DISCOURSE_REDIS_PORT']

smtp_address = ENV['DISCOURSE_SMTP_ADDRESS']
smtp_port = ENV['DISCOURSE_SMTP_PORT']
smtp_username = ENV['DISCOURSE_SMTP_USERNAME']
smtp_password = ENV['DISCOURSE_SMTP_PASSWORD']
```

#### 6.2 puma.rb
```ruby
# /opt/bitnami/discourse/config/puma.rb
workers ENV['DISCOURSE_PUMA_WORKERS'] || 2
threads_count = ENV['DISCOURSE_PUMA_THREADS'] || 5
threads threads_count, threads_count

environment ENV['RAILS_ENV'] || 'production'
directory '/opt/bitnami/discourse'

bind 'tcp://0.0.0.0:3000'
```

### 7. Runtime Scripts
#### 7.1 discourse-init
```bash
#!/bin/bash
# Component: discourse-init.sh

# Load environment variables
source /opt/bitnami/discourse/discourse-env

# Wait for database
wait_for_db() {
    while ! nc -z "$DISCOURSE_DATABASE_HOST" "$DISCOURSE_DATABASE_PORT"; do
        sleep 1
    done
}

# Wait for Redis
wait_for_redis() {
    while ! nc -z "$DISCOURSE_REDIS_HOST" "$DISCOURSE_REDIS_PORT"; do
        sleep 1
    done
}

# Initialize database if needed
initialize_database() {
    if ! discourse eval "Post.exists?"; then
        discourse db:migrate
        discourse db:seed_fu
    fi
}

# Main initialization
wait_for_db
wait_for_redis
initialize_database

# Start Puma
exec bundle exec puma -C config/puma.rb
```

### 8. Volume Configuration
```dockerfile
VOLUME [
    "/bitnami/discourse",
    "/opt/bitnami/discourse/public/uploads",
    "/opt/bitnami/discourse/public/backups",
    "/opt/bitnami/discourse/tmp"
]
```

### 9. Environment Variables
```bash
# Default environment variables
export DISCOURSE_DATABASE_HOST="postgresql"
export DISCOURSE_DATABASE_PORT="5432"
export DISCOURSE_DATABASE_NAME="bitnami_discourse"
export DISCOURSE_DATABASE_USERNAME="bn_discourse"
export DISCOURSE_DATABASE_PASSWORD=""
export DISCOURSE_REDIS_HOST="redis"
export DISCOURSE_REDIS_PORT="6379"
export DISCOURSE_HOSTNAME="localhost"
export DISCOURSE_SITE_NAME="My Discourse Forum"
export DISCOURSE_DEVELOPER_EMAILS="admin@example.com"
export DISCOURSE_SMTP_ADDRESS=""
export DISCOURSE_SMTP_PORT=""
export DISCOURSE_SMTP_USERNAME=""
export DISCOURSE_SMTP_PASSWORD=""
export DISCOURSE_SMTP_ENABLE_STARTTLS="true"
export DISCOURSE_ENABLE_HTTPS="false"
```

### 10. Health Check Configuration
```dockerfile
HEALTHCHECK --interval=30s --timeout=5s --start-period=5m --retries=3 \
    CMD curl -f http://localhost:3000/-/healthy || exit 1
```

## Runtime Behavior

### 1. Initialization Sequence
1. Container starts with discourse-init.sh
2. Environment variables are loaded
3. Wait for database and Redis availability
4. Database initialization if needed
5. Start Puma server

### 2. Volume Management
- `/bitnami/discourse`: Application data
- `/opt/bitnami/discourse/public/uploads`: User uploads
- `/opt/bitnami/discourse/public/backups`: Backup files
- `/opt/bitnami/discourse/tmp`: Temporary files

### 3. Process Hierarchy
1. Main process: Puma server
2. Worker processes (configurable)
3. Sidekiq process for background jobs

### 4. Security Considerations
- Non-root user execution
- Limited file permissions
- Environment-based configuration
- No default passwords

### 5. Backup Management
```bash
#!/bin/bash
# Component: backup-discourse.sh

cd /opt/bitnami/discourse
RAILS_ENV=production bundle exec rake backup:create
```

### 6. Plugin Management
```bash
#!/bin/bash
# Component: install-plugins.sh

cd /opt/bitnami/discourse/plugins

for plugin in ${DISCOURSE_PLUGINS//,/ }; do
    git clone --depth 1 $plugin
done

cd /opt/bitnami/discourse
RAILS_ENV=production bundle exec rake plugin:install_all_gems
```

## Configuration Schema

```typescript
interface DiscourseConfig {
  database: {
    host: string;
    port: number;
    name: string;
    username: string;
    password: string;
  };
  redis: {
    host: string;
    port: number;
  };
  smtp: {
    address: string;
    port: number;
    username: string;
    password: string;
    enableStartTLS: boolean;
  };
  server: {
    hostname: string;
    siteName: string;
    developerEmails: string[];
    enableHttps: boolean;
  };
  puma: {
    workers: number;
    threads: number;
  };
}
```

## Build Dependencies
```plaintext
build-essential
git
curl
libxml2-dev
libxslt-dev
postgresql-dev
imagemagick-dev
nodejs
yarn
ruby-dev
```

## Runtime Dependencies
```plaintext
postgresql-client
redis-tools
imagemagick
nginx
curl
libxml2
libxslt
postgresql-libs
```
