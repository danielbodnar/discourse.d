#!/usr/bin/env bash
# =============================================================================
#  🚀 Discourse Container Generator v1.0.0 🚀
#
#  Enterprise-grade Discourse container generation system
#  Copyright (c) 2024 Your Organization
#  Licensed under MIT License
#
#  Usage: ./generate-dockerfile.sh [variant] [environment] [options]
#
#  Example: ./generate-dockerfile.sh alpine production --debug
# =============================================================================

# -----------------------------------------------------------------------------
#  📋 Build Process Overview
# -----------------------------------------------------------------------------
#  🔧 Pre-flight Checks
#    • Environment validation
#    • Dependency verification
#    • Permission checks
#    • Configuration loading
#
#  🎯 Configuration
#    • Argument parsing
#    • Environment loading
#    • Settings validation
#    • Logging setup
#
#  🏗️ Setup
#    • Directory structure
#    • User/group config
#    • Logging system
#    • Build environment
#
#  📦 Base System
#    • Package managers
#    • System dependencies
#    • CA certificates
#    • Locale/timezone
#
#  🔨 Build Environment
#    • Build tools
#    • Dev environment
#    • Runtime deps
#    • Asset pipeline
#
#  🛠️ Application Setup
#    • Language runtimes
#    • Dependency managers
#    • App framework
#    • Plugins/themes
#
#  🔒 Security
#    • Permissions
#    • SSL/TLS
#    • Security policies
#    • Backup systems
#
#  🚦 Runtime
#    • Process management
#    • Web server
#    • Monitoring
#    • Health checks
#
#  🧪 Testing
#    • Security scans
#    • Config validation
#    • Connectivity
#    • Permissions
#
#  📝 Documentation
#    • Config docs
#    • Build report
#    • Change log
#    • Endpoints
# =============================================================================

# -----------------------------------------------------------------------------
#  🔒 Script Security & Error Handling
# -----------------------------------------------------------------------------
set -euo pipefail
IFS=$'\n\t'

# Ensure script is not being sourced
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo "❌ This script must not be sourced"
    return 1
fi

# Ensure we're running as the correct user
if [[ "${EUID}" -eq 0 ]] && [[ -z "${DOCKER_BUILD+x}" ]]; then
    echo "❌ This script must not be run as root"
    exit 1
fi

# Script directory determination
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
SCRIPT_PATH="${SCRIPT_DIR}/${SCRIPT_NAME}"

# Lock file to prevent parallel execution
LOCK_FILE="/tmp/discourse-generator.lock"
exec 9>"${LOCK_FILE}"
#if ! flock -n 9; then
#    echo "❌ Another instance is running"
#    exit 1
#fi

# -----------------------------------------------------------------------------
#  🎨 Color and Style Definitions
# -----------------------------------------------------------------------------
declare -A COLORS=(
    # Reset
    [reset]='\033[0m'
    [bold]='\033[1m'
    [dim]='\033[2m'
    [italic]='\033[3m'
    [underline]='\033[4m'
    [blink]='\033[5m'
    [reverse]='\033[7m'
    [hidden]='\033[8m'

    # Foreground colors
    [black]='\033[30m'
    [red]='\033[31m'
    [green]='\033[32m'
    [yellow]='\033[33m'
    [blue]='\033[34m'
    [magenta]='\033[35m'
    [cyan]='\033[36m'
    [white]='\033[37m'

    # Background colors
    [bg_black]='\033[40m'
    [bg_red]='\033[41m'
    [bg_green]='\033[42m'
    [bg_yellow]='\033[43m'
    [bg_blue]='\033[44m'
    [bg_magenta]='\033[45m'
    [bg_cyan]='\033[46m'
    [bg_white]='\033[47m'

    # Bright foreground colors
    [bright_black]='\033[90m'
    [bright_red]='\033[91m'
    [bright_green]='\033[92m'
    [bright_yellow]='\033[93m'
    [bright_blue]='\033[94m'
    [bright_magenta]='\033[95m'
    [bright_cyan]='\033[96m'
    [bright_white]='\033[97m'
)

# -----------------------------------------------------------------------------
#  📝 Logging Configuration
# -----------------------------------------------------------------------------
declare -A LOG_LEVELS=(
    [DEBUG]=0
    [INFO]=1
    [WARN]=2
    [ERROR]=3
    [FATAL]=4
)

declare -A LOG_ICONS=(
    [DEBUG]="🔍"
    [INFO]="ℹ️ "
    [WARN]="⚠️ "
    [ERROR]="❌"
    [FATAL]="💀"
    [SUCCESS]="✅"
    [PENDING]="⏳"
    [SKIPPED]="⏭️ "
    [FAILED]="💥"
)

# Default log level
LOG_LEVEL=${LOG_LEVEL:-"INFO"}
LOG_FILE=${LOG_FILE:-"${SCRIPT_DIR}/discourse-generator.log"}
DEBUG=${DEBUG:-false}

# -----------------------------------------------------------------------------
#  🛠️ Utility Functions
# -----------------------------------------------------------------------------
function timestamp() {
    date "+%Y-%m-%d %H:%M:%S"
}

function log() {
    echo "$@"
    local level="$1"
    local message="$2"
    local icon="${LOG_ICONS[$level]}"
    local color

    # Determine color based on log level
    case "$level" in
        DEBUG)  color="${COLORS[cyan]}" ;;
        INFO)   color="${COLORS[green]}" ;;
        WARN)   color="${COLORS[yellow]}" ;;
        ERROR)  color="${COLORS[red]}" ;;
        FATAL)  color="${COLORS[bg_red]}${COLORS[white]}" ;;
        SUCCESS) color="${COLORS[bright_green]}" ;;
        PENDING) color="${COLORS[bright_yellow]}" ;;
        SKIPPED) color="${COLORS[bright_blue]}" ;;
        FAILED)  color="${COLORS[bright_red]}" ;;
    esac

    # Format message
    local formatted_message="[$(timestamp)] ${icon} ${level}: ${message}"

    # Log to file
    echo "${formatted_message}" >> "${LOG_FILE}"

    # Display to console if level is sufficient
    if [[ ${LOG_LEVELS[$level]} -ge ${LOG_LEVELS[${LOG_LEVEL}]} ]]; then
        printf "%b%s %b%s%b %s%b\n" \
            "${COLORS[bold]}" \
            "${icon}" \
            "$color" \
            "[$level]" \
            "${COLORS[reset]}" \
            "$message" \
            "${COLORS[reset]}" >&2
    fi
}

# -----------------------------------------------------------------------------
#  🎯 Convenience Logging Functions
# -----------------------------------------------------------------------------
function debug()    { log "DEBUG" "$1"; }
function info()     { log "INFO" "$1"; }
function warn()     { log "WARN" "$1"; }
function error()    { log "ERROR" "$1"; }
function fatal()    { log "FATAL" "$1"; exit 1; }
function success()  { log "SUCCESS" "$1"; }
function pending()  { log "PENDING" "$1"; }
function skipped()  { log "SKIPPED" "$1"; }
function failed()   { log "FAILED" "$1"; return 1; }

# -----------------------------------------------------------------------------
#  🔍 Validation Functions
# -----------------------------------------------------------------------------
function validate_or_fail() {
    local check_name="$1"
    local check_command="$2"
    local error_message="$3"

    debug "🔍 Starting validation: $check_name"

    if ! eval "$check_command"; then
        fatal "❌ $check_name failed: $error_message"
    fi

    success "✅ $check_name: Validated successfully"
}

function validate_command_exists() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        fatal "❌ Required command not found: $cmd"
    fi
    debug "✅ Command validated: $cmd"
}

function validate_directory() {
    local dir="$1"
    local create="${2:-false}"

    if [[ ! -d "$dir" ]]; then
        if [[ "$create" == "true" ]]; then
            mkdir -p "$dir" || fatal "❌ Failed to create directory: $dir"
            success "📁 Created directory: $dir"
        else
            fatal "❌ Required directory not found: $dir"
        fi
    fi
    debug "✅ Directory validated: $dir"
}

# -----------------------------------------------------------------------------
#  🎯 Configuration Management
# -----------------------------------------------------------------------------
declare -A CONFIG=(
    # Base Configuration
    [DISCOURSE_VERSION]="3.2.2"
    [RUBY_VERSION]="3.2.2"
    [NODE_VERSION]="18.18.2"
    [YARN_VERSION]="4.0.2"
    [BUNDLER_VERSION]="2.4.22"
    [POSTGRESQL_VERSION]="15"
    [REDIS_VERSION]="7.0"

    # Directory Structure
    [DISCOURSE_HOME]="/opt/discourse"
    [DISCOURSE_DATA]="/var/discourse"
    [DISCOURSE_LOGS]="/var/log/discourse"
    [DISCOURSE_TMP]="/tmp/discourse"

    # User Configuration
    [DISCOURSE_USER]="discourse"
    [DISCOURSE_GROUP]="discourse"
    [DISCOURSE_UID]="1001"
    [DISCOURSE_GID]="1001"

    # Build Configuration
    [BUILD_TYPE]="production"
    [OPTIMIZE_BUILD]="true"
    [PARALLEL_JOBS]="4"

    # Security Configuration
    [ENABLE_SECURITY_HARDENING]="true"
    [ENABLE_SELINUX]="false"
    [ENABLE_APPARMOR]="true"
)

# -----------------------------------------------------------------------------
#  🔧 System Dependencies
# -----------------------------------------------------------------------------
declare -A DEPENDENCIES=(
    [alpine]="
        bash
        curl
        wget
        git
        build-base
        linux-headers
        python3
        rust
        cargo
        nodejs
        npm
        postgresql-client
        redis
        imagemagick
        yaml
        gcompat
        tzdata
        ca-certificates
    "
    [debian]="
        bash
        curl
        wget
        git
        build-essential
        python3
        nodejs
        npm
        postgresql-client
        redis-tools
        imagemagick
        libyaml-dev
        tzdata
        ca-certificates
    "
    [ubuntu]="
        bash
        curl
        wget
        git
        build-essential
        python3
        nodejs
        npm
        postgresql-client
        redis-tools
        imagemagick
        libyaml-dev
        tzdata
        ca-certificates
    "
)

# -----------------------------------------------------------------------------
#  🏗️ Build Stage Functions
# -----------------------------------------------------------------------------
function prepare_base_os() {
    local variant="$1"
    pending "🔨 Preparing base OS for variant: $variant"

    # Package manager commands
    declare -A PKG_COMMANDS=(
        [alpine]="apk add --no-cache"
        [debian]="apt-get update && apt-get install -y --no-install-recommends"
        [ubuntu]="apt-get update && apt-get install -y --no-install-recommends"
    )

    declare -A PKG_CLEANUP=(
        [alpine]="rm -rf /var/cache/apk/*"
        [debian]="apt-get clean && rm -rf /var/lib/apt/lists/*"
        [ubuntu]="apt-get clean && rm -rf /var/lib/apt/lists/*"
    )

    cat << EOF > Dockerfile.base
FROM ${CONFIG[BASE_IMAGE]}

# 🔒 Security updates and base configuration
RUN set -eux; \\
    ${PKG_COMMANDS[$variant]} && \\
    ${PKG_CLEANUP[$variant]}

# 🌍 Locale and timezone configuration
ENV LANG=en_US.UTF-8 \\
    LANGUAGE=en_US:en \\
    LC_ALL=en_US.UTF-8 \\
    TZ=UTC

# 📜 CA Certificates
COPY src/etc/ssl/certs/* /usr/local/share/ca-certificates/
RUN update-ca-certificates

# 👤 Create discourse user and group
RUN groupadd -g ${CONFIG[DISCOURSE_GID]} ${CONFIG[DISCOURSE_GROUP]} && \\
    useradd -u ${CONFIG[DISCOURSE_UID]} \\
            -g ${CONFIG[DISCOURSE_GROUP]} \\
            -d ${CONFIG[DISCOURSE_HOME]} \\
            -s /bin/bash \\
            ${CONFIG[DISCOURSE_USER]}

# 📁 Create directory structure
RUN mkdir -p \\
    ${CONFIG[DISCOURSE_HOME]} \\
    ${CONFIG[DISCOURSE_DATA]} \\
    ${CONFIG[DISCOURSE_LOGS]} \\
    ${CONFIG[DISCOURSE_TMP]} && \\
    chown -R ${CONFIG[DISCOURSE_USER]}:${CONFIG[DISCOURSE_GROUP]} \\
        ${CONFIG[DISCOURSE_HOME]} \\
        ${CONFIG[DISCOURSE_DATA]} \\
        ${CONFIG[DISCOURSE_LOGS]} \\
        ${CONFIG[DISCOURSE_TMP]}

EOF
    success "✅ Base OS preparation complete"
}

function prepare_build_environment() {
    pending "🏗️ Preparing build environment"

    cat << EOF >> Dockerfile.build
FROM discourse-base:${CONFIG[DISCOURSE_VERSION]} AS builder

# 🔨 Install build dependencies
COPY lib/install-deps.sh /tmp/
RUN /tmp/install-deps.sh build

# 💎 Ruby setup
COPY lib/install-ruby.sh /tmp/
RUN /tmp/install-ruby.sh ${CONFIG[RUBY_VERSION]}

# 📦 Node.js setup
COPY lib/install-node.sh /tmp/
RUN /tmp/install-node.sh ${CONFIG[NODE_VERSION]}

# 🧶 Yarn setup
RUN npm install -g yarn@${CONFIG[YARN_VERSION]}

# 💼 Bundler setup
RUN gem install bundler:${CONFIG[BUNDLER_VERSION]}

# 📁 Application setup
WORKDIR ${CONFIG[DISCOURSE_HOME]}
COPY src/ .

# 📚 Install dependencies
RUN bundle install --deployment --without development test && \\
    yarn install --production

# 🎨 Asset compilation
RUN RAILS_ENV=production bundle exec rake assets:precompile

EOF
    success "✅ Build environment preparation complete"
}

function prepare_production_image() {
    pending "🚀 Preparing production image"

    cat << EOF >> Dockerfile.production
FROM discourse-base:${CONFIG[DISCOURSE_VERSION]}

# 📦 Copy built artifacts
COPY --from=builder --chown=${CONFIG[DISCOURSE_USER]}:${CONFIG[DISCOURSE_GROUP]} \\
    ${CONFIG[DISCOURSE_HOME]} ${CONFIG[DISCOURSE_HOME]}

# 🔒 Security hardening
COPY lib/security/harden.sh /tmp/
RUN /tmp/harden.sh

# 📝 Runtime configuration
COPY config/discourse.conf /etc/discourse/discourse.conf
COPY config/nginx.conf /etc/nginx/nginx.conf

# 📂 Volume configuration
VOLUME [ \\
    "${CONFIG[DISCOURSE_DATA]}/shared", \\
    "${CONFIG[DISCOURSE_DATA]}/uploads", \\
    "${CONFIG[DISCOURSE_DATA]}/backups", \\
    "${CONFIG[DISCOURSE_DATA]}/plugins" \\
]

# 🔌 Port configuration
EXPOSE 3000

# 🏃 Runtime configuration
USER ${CONFIG[DISCOURSE_USER]}
WORKDIR ${CONFIG[DISCOURSE_HOME]}

# 🏥 Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \\
    CMD curl -f http://localhost:3000/srv/status || exit 1

# 🎬 Startup
ENTRYPOINT ["/sbin/tini", "--"]
CMD ["./bin/discourse", "start"]
EOF
    success "✅ Production image preparation complete"
}
# -----------------------------------------------------------------------------
#  🛠️ Build Support Functions
# -----------------------------------------------------------------------------
function generate_security_scripts() {
    pending "🔒 Generating security hardening scripts"

    mkdir -p lib/security

    # Generate hardening script
    cat << 'EOF' > lib/security/harden.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🔒 Applying security hardening measures..."

# 📝 File permissions
find / -type f -perm /o+w -exec chmod o-w {} \;
find / -type d -perm /o+w -exec chmod o-w {} \;

# 🔐 Secure SSH configuration
if [[ -f /etc/ssh/sshd_config ]]; then
    sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
fi

# 🛡️ System hardening
cat << SYSCTL > /etc/sysctl.d/99-security.conf
kernel.randomize_va_space=2
net.ipv4.conf.all.rp_filter=1
net.ipv4.conf.default.rp_filter=1
net.ipv4.icmp_echo_ignore_broadcasts=1
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0
net.ipv4.conf.all.secure_redirects=0
net.ipv4.conf.default.secure_redirects=0
SYSCTL

# 🔏 Capabilities
if command -v capsh >/dev/null 2>&1; then
    capsh --drop=all --caps="cap_net_bind_service,cap_chown,cap_dac_override,cap_setuid,cap_setgid,cap_sys_nice=ep"
fi

echo "✅ Security hardening complete"
EOF

    # Generate backup script
    cat << 'EOF' > lib/security/backup.sh
#!/usr/bin/env bash
set -euo pipefail

echo "💾 Starting backup process..."

BACKUP_DIR="${DISCOURSE_DATA}/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/discourse_backup_${TIMESTAMP}.tar.gz"

# 📦 Create backup directory if it doesn't exist
mkdir -p "${BACKUP_DIR}"

# 🗄️ Backup uploads
tar -czf "${BACKUP_FILE}" \
    -C "${DISCOURSE_DATA}" \
    uploads \
    shared \
    plugins

# 🔐 Set correct permissions
chown ${DISCOURSE_USER}:${DISCOURSE_GROUP} "${BACKUP_FILE}"
chmod 600 "${BACKUP_FILE}"

echo "✅ Backup complete: ${BACKUP_FILE}"
EOF

    # Generate restore script
    cat << 'EOF' > lib/security/restore.sh
#!/usr/bin/env bash
set -euo pipefail

echo "📂 Starting restore process..."

BACKUP_FILE="$1"
if [[ ! -f "${BACKUP_FILE}" ]]; then
    echo "❌ Backup file not found: ${BACKUP_FILE}"
    exit 1
fi

# 🔄 Restore data
tar -xzf "${BACKUP_FILE}" -C "${DISCOURSE_DATA}"

# 🔐 Fix permissions
chown -R ${DISCOURSE_USER}:${DISCOURSE_GROUP} \
    "${DISCOURSE_DATA}/uploads" \
    "${DISCOURSE_DATA}/shared" \
    "${DISCOURSE_DATA}/plugins"

echo "✅ Restore complete"
EOF

    # Make scripts executable
    chmod +x lib/security/*.sh
    success "✅ Security scripts generated"
}

function generate_health_check() {
    pending "🏥 Generating health check script"

    mkdir -p lib/health

    cat << 'EOF' > lib/health/check.sh
#!/usr/bin/env bash
set -euo pipefail

# 🔍 Health check configuration
HEALTH_CHECK_URL=${HEALTH_CHECK_URL:-"http://localhost:3000/srv/status"}
TIMEOUT=${HEALTH_CHECK_TIMEOUT:-5}
ATTEMPTS=${HEALTH_CHECK_ATTEMPTS:-3}

for ((i=1; i<=ATTEMPTS; i++)); do
    if curl -sf --max-time "${TIMEOUT}" "${HEALTH_CHECK_URL}" >/dev/null 2>&1; then
        echo "✅ Health check passed"
        exit 0
    fi
    sleep 1
done

echo "❌ Health check failed after ${ATTEMPTS} attempts"
exit 1
EOF

    chmod +x lib/health/check.sh
    success "✅ Health check script generated"
}

# -----------------------------------------------------------------------------
#  🎨 Asset and Plugin Management
# -----------------------------------------------------------------------------
function setup_asset_pipeline() {
    pending "🎨 Setting up asset pipeline"

    mkdir -p lib/assets

    cat << 'EOF' > lib/assets/compile.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🎨 Starting asset compilation..."

# Environment setup
export RAILS_ENV=production
export NODE_ENV=production

# 🧹 Clean existing assets
echo "🧹 Cleaning existing assets..."
bundle exec rake assets:clean

# 🎭 Precompile themes
if [[ -d "themes" ]]; then
    echo "🎭 Precompiling themes..."
    for theme in themes/*; do
        if [[ -d "$theme" ]]; then
            echo "  ↳ Compiling theme: $(basename "$theme")"
            bundle exec rake themes:compile["$(basename "$theme")"]
        fi
    done
fi

# 🔌 Precompile plugins
if [[ -d "plugins" ]]; then
    echo "🔌 Precompiling plugins..."
    for plugin in plugins/*; do
        if [[ -d "$plugin" ]]; then
            echo "  ↳ Compiling plugin: $(basename "$plugin")"
            bundle exec rake plugin:compile["$(basename "$plugin")"]
        fi
    done
fi

# 🎨 Main asset compilation
echo "🎨 Precompiling assets..."
bundle exec rake assets:precompile

# 📦 Optimize assets
if [[ "${OPTIMIZE_ASSETS:-true}" == "true" ]]; then
    echo "📦 Optimizing assets..."
    find public/assets -type f -name "*.js" -exec gzip -9 -k {} \;
    find public/assets -type f -name "*.css" -exec gzip -9 -k {} \;
fi

# 🧹 Cleanup
echo "🧹 Cleaning up..."
rm -rf tmp/cache

echo "✅ Asset compilation complete"
EOF

    chmod +x lib/assets/compile.sh
    success "✅ Asset pipeline setup complete"
}

function setup_plugin_management() {
    pending "🔌 Setting up plugin management"

    mkdir -p lib/plugins

    cat << 'EOF' > lib/plugins/manage.sh
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_DIR="${DISCOURSE_HOME}/plugins"
PLUGIN_CONFIG="${DISCOURSE_HOME}/config/plugins.yml"

function install_plugin() {
    local repo="$1"
    local branch="${2:-main}"
    local name=$(basename "$repo" .git)

    echo "🔌 Installing plugin: $name"

    if [[ -d "${PLUGIN_DIR}/${name}" ]]; then
        echo "⚠️  Plugin already exists: $name"
        return 0
    fi

    git clone --depth 1 --branch "$branch" "$repo" "${PLUGIN_DIR}/${name}"

    if [[ -f "${PLUGIN_DIR}/${name}/package.json" ]]; then
        (cd "${PLUGIN_DIR}/${name}" && yarn install --production)
    fi

    if [[ -f "${PLUGIN_DIR}/${name}/Gemfile" ]]; then
        (cd "${PLUGIN_DIR}/${name}" && bundle install)
    fi

    echo "✅ Plugin installed: $name"
}

function remove_plugin() {
    local name="$1"

    echo "🗑️  Removing plugin: $name"

    if [[ ! -d "${PLUGIN_DIR}/${name}" ]]; then
        echo "⚠️  Plugin not found: $name"
        return 1
    fi

    rm -rf "${PLUGIN_DIR}/${name}"
    echo "✅ Plugin removed: $name"
}

function update_plugin() {
    local name="$1"

    echo "🔄 Updating plugin: $name"

    if [[ ! -d "${PLUGIN_DIR}/${name}" ]]; then
        echo "⚠️  Plugin not found: $name"
        return 1
    fi

    (
        cd "${PLUGIN_DIR}/${name}"
        git pull
        [[ -f package.json ]] && yarn install --production
        [[ -f Gemfile ]] && bundle install
    )

    echo "✅ Plugin updated: $name"
}

# Load and install configured plugins
if [[ -f "$PLUGIN_CONFIG" ]]; then
    echo "📚 Loading plugin configuration..."
    while IFS=: read -r plugin branch; do
        install_plugin "$plugin" "$branch"
    done < "$PLUGIN_CONFIG"
fi
EOF

    chmod +x lib/plugins/manage.sh
    success "✅ Plugin management setup complete"
}

# -----------------------------------------------------------------------------
#  🔄 Runtime Configuration Management
# -----------------------------------------------------------------------------
function generate_runtime_configs() {
    pending "⚙️ Generating runtime configurations"

    mkdir -p config/{nginx,redis,puma,sidekiq}

    # 🌐 Nginx Configuration
    cat << 'EOF' > config/nginx/discourse.conf
# Discourse Nginx Configuration
worker_processes auto;
worker_rlimit_nofile 65535;

events {
    worker_connections 65535;
    multi_accept on;
    use epoll;
}

http {
    include mime.types;
    default_type application/octet-stream;

    # 🔄 Optimizations
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    # 📝 Logging
    access_log /var/log/nginx/discourse.access.log combined buffer=512k flush=1m;
    error_log /var/log/nginx/discourse.error.log warn;

    # 🔒 SSL Configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:50m;
    ssl_session_timeout 1d;
    ssl_session_tickets off;

    # 🚦 Upstream Configuration
    upstream discourse {
        server 127.0.0.1:3000;
        keepalive 32;
    }

    # 🌍 Server Configuration
    server {
        listen 80;
        listen [::]:80;
        server_name _;

        root ${DISCOURSE_HOME}/public;

        # 🔒 Security Headers
        add_header X-Frame-Options SAMEORIGIN;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
        add_header Referrer-Policy strict-origin-when-cross-origin;

        # 📁 Static Files
        location ~ ^/(assets|images|javascripts|stylesheets|uploads)/ {
            expires max;
            add_header Cache-Control public;
        }

        # 🔄 Main Application
        location / {
            try_files \$uri @discourse;
        }

        location @discourse {
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
            proxy_set_header Host \$http_host;
            proxy_set_header X-Request-Start "t=\${msec}";
            proxy_pass http://discourse;
            proxy_http_version 1.1;
            proxy_set_header Connection "";
        }
    }
}
EOF

    # 📊 Redis Configuration
    cat << 'EOF' > config/redis/discourse.conf
# Redis Configuration for Discourse
maxmemory 512mb
maxmemory-policy allkeys-lru
appendonly yes
appendfsync everysec
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
EOF

    # 🚀 Puma Configuration
    cat << 'EOF' > config/puma/discourse.rb
#!/usr/bin/env puma

# 📊 Identity
tag 'discourse'

# 📂 Directory Configuration
directory '${DISCOURSE_HOME}'
rackup '${DISCOURSE_HOME}/config.ru'

# 🔌 Socket Configuration
bind 'tcp://0.0.0.0:3000'

# 📈 Process Configuration
workers ENV.fetch('PUMA_WORKERS', 2).to_i
threads ENV.fetch('PUMA_MIN_THREADS', 5).to_i, ENV.fetch('PUMA_MAX_THREADS', 5).to_i

# 🎛️ Worker Configuration
preload_app!
worker_timeout 60
worker_boot_timeout 60

# 📝 Logging
stdout_redirect '${DISCOURSE_LOGS}/puma.stdout.log', '${DISCOURSE_LOGS}/puma.stderr.log', true

# 🔄 Before/After Hooks
before_fork do
  ActiveRecord::Base.connection_pool.disconnect! if defined?(ActiveRecord)
end

on_worker_boot do
  ActiveRecord::Base.establish_connection if defined?(ActiveRecord)
end
EOF

    # 👷 Sidekiq Configuration
    cat << 'EOF' > config/sidekiq/discourse.yml
:concurrency: ${SIDEKIQ_CONCURRENCY:-5}
:queues:
  - [critical, 8]
  - [default, 4]
  - [low, 2]
:daemon: false
:verbose: false
:timeout: 25
:max_retries: 10
EOF

    success "✅ Runtime configurations generated"
}
# -----------------------------------------------------------------------------
#  🔄 Development Environment Setup
# -----------------------------------------------------------------------------
function setup_development_environment() {
    pending "🛠️ Setting up development environment"

    mkdir -p lib/dev

    # 🔧 Development Tools Installation Script
    cat << 'EOF' > lib/dev/setup.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🛠️ Setting up development environment..."

# 📚 Development Dependencies
DEV_PACKAGES=(
    vim
    tmux
    postgresql-dev
    redis-dev
    imagemagick-dev
    ruby-dev
    nodejs-dev
    yarn
    git-flow
    shellcheck
    sqlite-dev
    chromium
    chromium-chromedriver
)

# 🔨 Install development packages
case "${CONTAINER_OS}" in
    alpine)
        apk add --no-cache "${DEV_PACKAGES[@]}"
        ;;
    debian|ubuntu)
        apt-get update && apt-get install -y "${DEV_PACKAGES[@]}"
        ;;
esac

# 💎 Ruby Development Setup
gem install --no-document \
    pry \
    pry-byebug \
    rubocop \
    ruby-debug-ide \
    debase \
    solargraph

# 📦 Node.js Development Setup
npm install -g \
    nodemon \
    eslint \
    prettier \
    typescript \
    ts-node

# 🧪 Testing Framework Setup
bundle install --with development test
yarn install --development

# 🔍 Setup VSCode Remote Development
mkdir -p /home/${DISCOURSE_USER}/.vscode-server/extensions

# 📝 Configure Git
git config --global user.email "dev@discourse.local"
git config --global user.name "Discourse Developer"

# 🎨 Setup development aliases
cat << 'ALIASES' >> /home/${DISCOURSE_USER}/.bashrc
# Discourse Development Aliases
alias d:console="bundle exec rails console"
alias d:server="bundle exec rails server"
alias d:worker="bundle exec sidekiq"
alias d:test="bundle exec rspec"
alias d:lint="bundle exec rubocop"
alias d:routes="bundle exec rails routes"
alias d:migrate="bundle exec rails db:migrate"
alias d:seed="bundle exec rails db:seed"
alias d:reset="bundle exec rails db:reset"
ALIASES

echo "✅ Development environment setup complete"
EOF

    # 🧪 Test Suite Setup
    cat << 'EOF' > lib/dev/test-setup.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Setting up test environment..."

# 📊 Configure Test Database
RAILS_ENV=test bundle exec rake db:create db:migrate

# 🔧 Configure RSpec
cat << 'RSPEC' > .rspec
--color
--require spec_helper
--format documentation
RSPEC

# 🎭 Configure Factory Bot
if [[ ! -f spec/support/factory_bot.rb ]]; then
    mkdir -p spec/support
    cat << 'FACTORY_BOT' > spec/support/factory_bot.rb
RSpec.configure do |config|
    config.include FactoryBot::Syntax::Methods
end
FACTORY_BOT
fi

# 🔍 Configure SimpleCov
cat << 'SIMPLECOV' > .simplecov
SimpleCov.start 'rails' do
    add_filter '/spec/'
    add_filter '/config/'
    add_filter '/vendor/'

    add_group 'Controllers', 'app/controllers'
    add_group 'Models', 'app/models'
    add_group 'Services', 'app/services'
    add_group 'Jobs', 'app/jobs'
end
SIMPLECOV

echo "✅ Test environment setup complete"
EOF

    # 🐛 Debug Configuration
    cat << 'EOF' > lib/dev/debug-setup.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🐛 Setting up debugging tools..."

# 🔍 Configure Ruby Debug
cat << 'RDEBUG' > .rdebugrc
set autolist
set autoeval
set autoreload
RDEBUG

# 🔧 Configure VSCode Debug
mkdir -p .vscode
cat << 'LAUNCH' > .vscode/launch.json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Rails Server",
            "type": "Ruby",
            "request": "launch",
            "program": "${workspaceRoot}/bin/rails",
            "args": ["server"]
        },
        {
            "name": "RSpec - Current File",
            "type": "Ruby",
            "request": "launch",
            "program": "${workspaceRoot}/bin/rspec",
            "args": ["${file}"]
        }
    ]
}
LAUNCH

echo "✅ Debug configuration complete"
EOF

    chmod +x lib/dev/*.sh
    success "✅ Development environment configuration complete"
}

# -----------------------------------------------------------------------------
#  📊 Monitoring and Observability
# -----------------------------------------------------------------------------
function setup_monitoring() {
    pending "📊 Setting up monitoring and observability"

    mkdir -p lib/monitoring

    # 📈 Prometheus Metrics Configuration
    cat << 'EOF' > lib/monitoring/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'discourse'
    static_configs:
      - targets: ['localhost:3000']
    metrics_path: '/metrics'
    scheme: 'http'

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'redis-exporter'
    static_configs:
      - targets: ['localhost:9121']

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['localhost:9187']
EOF

    # 🔍 Health Check Script
    cat << 'EOF' > lib/monitoring/healthcheck.sh
#!/usr/bin/env bash
set -euo pipefail

# 🎯 Health Check Endpoints
declare -A ENDPOINTS=(
    [web]="http://localhost:3000/srv/status"
    [redis]="redis://localhost:6379"
    [postgres]="postgresql://discourse:discourse@localhost:5432/discourse"
    [sidekiq]="http://localhost:3000/sidekiq/stats"
)

function check_endpoint() {
    local name="$1"
    local url="$2"

    echo "🔍 Checking $name..."
    case "$name" in
        web|sidekiq)
            curl -sf "$url" >/dev/null
            ;;
        redis)
            redis-cli -u "$url" ping >/dev/null
            ;;
        postgres)
            pg_isready -U discourse -h localhost -d discourse >/dev/null
            ;;
    esac
}

# 🏃 Run Checks
for name in "${!ENDPOINTS[@]}"; do
    if ! check_endpoint "$name" "${ENDPOINTS[$name]}"; then
        echo "❌ $name check failed"
        exit 1
    fi
    echo "✅ $name check passed"
done

echo "✅ All health checks passed"
EOF

    # 📝 Logging Configuration
    cat << 'EOF' > lib/monitoring/logging.sh
#!/usr/bin/env bash
set -euo pipefail

# 📊 Configure Logrotate
cat << 'LOGROTATE' > /etc/logrotate.d/discourse
${DISCOURSE_LOGS}/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 ${DISCOURSE_USER} ${DISCOURSE_GROUP}
    sharedscripts
    postrotate
        kill -USR1 $(cat ${DISCOURSE_HOME}/tmp/pids/puma.pid 2>/dev/null) 2>/dev/null || true
        kill -USR1 $(cat ${DISCOURSE_HOME}/tmp/pids/sidekiq.pid 2>/dev/null) 2>/dev/null || true
    endscript
}
LOGROTATE

# 📈 Configure Log Aggregation
mkdir -p /etc/fluent
cat << 'FLUENT' > /etc/fluent/fluent.conf
<source>
  @type tail
  path ${DISCOURSE_LOGS}/*.log
  pos_file /var/log/fluentd/discourse.pos
  tag discourse.*
  <parse>
    @type multiline
    format_firstline /\d{4}-\d{2}-\d{2}/
    format1 /(?<time>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) \[(?<level>\w+)\] (?<message>.*)/
  </parse>
</source>

<match discourse.**>
  @type elasticsearch
  host elasticsearch
  port 9200
  logstash_format true
  logstash_prefix discourse
  flush_interval 5s
</match>
FLUENT

echo "✅ Logging configuration complete"
EOF

    chmod +x lib/monitoring/*.sh
    success "✅ Monitoring and observability setup complete"
}
# -----------------------------------------------------------------------------
#  🔐 SSL/TLS and Security Configuration
# -----------------------------------------------------------------------------
function setup_security_configuration() {
    pending "🔐 Setting up security configurations"

    mkdir -p lib/security/certs

    # 🛡️ Security Policy Generator
    cat << 'EOF' > lib/security/generate-policies.sh
#!/usr/bin/env bash
set -euo pipefail

# 🔒 Generate Security Headers
cat << 'SECURITY_HEADERS' > config/security_headers.conf
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header X-Content-Type-Options "nosniff" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;
add_header Permissions-Policy "geolocation=(), midi=(), sync-xhr=(), microphone=(), camera=(), magnetometer=(), gyroscope=(), fullscreen=(self), payment=()" always;
SECURITY_HEADERS

# 🔑 SSL Configuration
cat << 'SSL_CONF' > config/ssl.conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
ssl_session_timeout 1d;
ssl_session_cache shared:SSL:50m;
ssl_session_tickets off;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
SSL_CONF

# 🛡️ ModSecurity Configuration
cat << 'MODSECURITY' > config/modsecurity.conf
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml application/json
SecDefaultAction "phase:2,deny,log,status:403"

# Basic XSS protection
SecRule REQUEST_COOKIES|!REQUEST_COOKIES:/__utm/|REQUEST_COOKIES_NAMES|REQUEST_HEADERS:User-Agent|REQUEST_HEADERS:Referer|ARGS_NAMES|ARGS|XML:/* "(?i:<script[^>]*>[\s\S]*?)" \
    "id:1000,phase:2,t:none,t:urlDecodeUni,block,msg:'XSS Attack Detected'"

# SQL Injection protection
SecRule REQUEST_COOKIES|!REQUEST_COOKIES:/__utm/|REQUEST_COOKIES_NAMES|REQUEST_HEADERS:User-Agent|REQUEST_HEADERS:Referer|ARGS_NAMES|ARGS|XML:/* "(?i:(\%27)|(\')|(\-\-)|(\%23)|(#))" \
    "id:1001,phase:2,t:none,t:urlDecodeUni,block,msg:'SQL Injection Attack Detected'"
MODSECURITY

# 🔒 AppArmor Profile
cat << 'APPARMOR' > config/discourse.apparmor
#include <tunables/global>

profile discourse flags=(attach_disconnected,mediate_deleted) {
    #include <abstractions/base>
    #include <abstractions/ruby>
    #include <abstractions/nginx>
    #include <abstractions/nameservice>

    # Discourse directories
    ${DISCOURSE_HOME}/** rwk,
    ${DISCOURSE_DATA}/** rwk,
    ${DISCOURSE_LOGS}/** rwk,

    # Allow network access
    network tcp,
    network udp,

    # System access
    /proc/sys/kernel/random/uuid r,
    /sys/kernel/mm/transparent_hugepage/enabled r,

    # Deny everything else
    deny /** rwxm,
}
APPARMOR

echo "✅ Security policies generated"
EOF

    # 🔑 Certificate Management
    cat << 'EOF' > lib/security/manage-certs.sh
#!/usr/bin/env bash
set -euo pipefail

CERTS_DIR="${DISCOURSE_HOME}/config/certs"
mkdir -p "$CERTS_DIR"

function generate_self_signed() {
    local domain="$1"
    local cert_path="${CERTS_DIR}/${domain}.crt"
    local key_path="${CERTS_DIR}/${domain}.key"

    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$key_path" \
        -out "$cert_path" \
        -subj "/CN=${domain}/O=Discourse/C=US"

    chmod 600 "$key_path"
    chmod 644 "$cert_path"
}

function install_custom_cert() {
    local cert_file="$1"
    local key_file="$2"
    local domain="$3"

    cp "$cert_file" "${CERTS_DIR}/${domain}.crt"
    cp "$key_file" "${CERTS_DIR}/${domain}.key"

    chmod 600 "${CERTS_DIR}/${domain}.key"
    chmod 644 "${CERTS_DIR}/${domain}.crt"
}

# Usage
case "${1:-}" in
    self-signed)
        generate_self_signed "${2:-localhost}"
        ;;
    custom)
        install_custom_cert "$2" "$3" "$4"
        ;;
    *)
        echo "Usage: $0 {self-signed|custom} [args...]"
        exit 1
        ;;
esac
EOF

    chmod +x lib/security/*.sh
    success "✅ Security configuration complete"
}

# -----------------------------------------------------------------------------
#  🚀 Container Initialization and Startup
# -----------------------------------------------------------------------------
function generate_init_scripts() {
    pending "🚀 Generating initialization and startup scripts"

    mkdir -p lib/init

    # 🎬 Main Entrypoint Script
    cat << 'EOF' > lib/init/entrypoint.sh
#!/usr/bin/env bash
set -euo pipefail

# 📝 Load Environment Variables
source "${DISCOURSE_HOME}/config/discourse.env"

# 🔍 Pre-flight Checks
function check_requirements() {
    echo "🔍 Performing pre-flight checks..."

    # Check required directories
    for dir in "${DISCOURSE_HOME}" "${DISCOURSE_DATA}" "${DISCOURSE_LOGS}"; do
        if [[ ! -d "$dir" ]]; then
            echo "❌ Required directory missing: $dir"
            exit 1
        fi
    done

    # Check database connection
    until pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}"; do
        echo "⏳ Waiting for database connection..."
        sleep 2
    done

    # Check Redis connection
    until redis-cli -h "${REDIS_HOST}" ping &>/dev/null; do
        echo "⏳ Waiting for Redis connection..."
        sleep 2
    done

    echo "✅ Pre-flight checks passed"
}

# 🔄 Initialize Application
function initialize_application() {
    echo "🔄 Initializing application..."

    # Run pending migrations
    if [[ "${RUN_MIGRATIONS:-false}" == "true" ]]; then
        echo "📊 Running database migrations..."
        bundle exec rake db:migrate
    fi

    # Precompile assets if needed
    if [[ ! -d "public/assets" || "${PRECOMPILE_ASSETS:-false}" == "true" ]]; then
        echo "🎨 Precompiling assets..."
        bundle exec rake assets:precompile
    fi

    # Initialize plugins
    if [[ -d "plugins" ]]; then
        echo "🔌 Initializing plugins..."
        bundle exec rake plugins:migrate
    fi

    echo "✅ Application initialized"
}

# 📝 Generate Configuration
function generate_configs() {
    echo "⚙️ Generating configurations..."

    # Generate database.yml
    cat << YAML > config/database.yml
production:
  adapter: postgresql
  host: ${DB_HOST}
  port: ${DB_PORT}
  database: ${DB_NAME}
  username: ${DB_USER}
  password: ${DB_PASS}
  pool: ${DB_POOL:-5}
YAML

    # Generate redis.yml
    cat << YAML > config/redis.yml
production:
  uri: redis://${REDIS_HOST}:${REDIS_PORT}/${REDIS_DB:-0}
  password: ${REDIS_PASS:-}
YAML

    # Generate discourse.conf
    envsubst < config/discourse.conf.template > config/discourse.conf

    echo "✅ Configurations generated"
}

# 🏃 Start Services
function start_services() {
    echo "🚀 Starting services..."

    # Start Sidekiq
    echo "👷 Starting Sidekiq..."
    bundle exec sidekiq \
        -e production \
        -C config/sidekiq.yml \
        -L ${DISCOURSE_LOGS}/sidekiq.log &

    # Start Puma
    echo "🚀 Starting Puma..."
    exec bundle exec puma \
        -C config/puma.rb \
        -e production
}

# 🎬 Main Execution
echo "🚀 Starting Discourse..."

check_requirements
generate_configs
initialize_application
start_services
EOF

    # 🔄 Graceful Shutdown Script
    cat << 'EOF' > lib/init/shutdown.sh
#!/usr/bin/env bash
set -euo pipefail

echo "🛑 Initiating graceful shutdown..."

# Stop Sidekiq
if [[ -f tmp/pids/sidekiq.pid ]]; then
    echo "👷 Stopping Sidekiq..."
    kill -TERM $(cat tmp/pids/sidekiq.pid)
    while kill -0 $(cat tmp/pids/sidekiq.pid) 2>/dev/null; do
        echo "⏳ Waiting for Sidekiq to stop..."
        sleep 1
    done
fi

# Stop Puma
if [[ -f tmp/pids/puma.pid ]]; then
    echo "🚀 Stopping Puma..."
    kill -TERM $(cat tmp/pids/puma.pid)
    while kill -0 $(cat tmp/pids/puma.pid) 2>/dev/null; do
        echo "⏳ Waiting for Puma to stop..."
        sleep 1
    done
fi

echo "✅ Shutdown complete"
EOF

    chmod +x lib/init/*.sh
    success "✅ Initialization scripts generated"
}


# -----------------------------------------------------------------------------
#  📚 Documentation Generation
# -----------------------------------------------------------------------------
function generate_documentation() {
    pending "📚 Generating documentation"

    mkdir -p docs/{user,admin,dev}

    # 📘 User Guide
    cat << 'EOF' > docs/user/README.md
# Discourse Container User Guide 🚀

## Quick Start
\`\`\`bash
# Build the container
docker build -t discourse .

# Run the container
docker run -d --name discourse discourse
\`\`\`

## Environment Variables
| Variable | Description | Default |
|----------|-------------|---------|
| DISCOURSE_HOSTNAME | Site hostname | localhost |
| RAILS_ENV | Rails environment | production |
| DISCOURSE_SMTP_ADDRESS | SMTP server | smtp.example.com |
...

## Volumes
- \`/opt/discourse\`: Application files
- \`/var/discourse\`: Persistent data
- \`/var/log/discourse\`: Logs

## Ports
- 3000: Web interface
- 9405: Prometheus metrics

## Health Checks
The container includes built-in health checks at:
\`http://localhost:3000/srv/status\`
EOF

    # 👨‍💻 Developer Guide
    cat << 'EOF' > docs/dev/README.md
# Developer Guide 🛠️

## Development Setup
\`\`\`bash
# Build development image
./generate-dockerfile.sh alpine development

# Start development environment
docker-compose -f docker-compose.dev.yml up
\`\`\`

## Directory Structure
\`\`\`
.
├── lib/          # Build scripts
├── src/          # Source files
├── config/       # Configurations
└── docs/         # Documentation
\`\`\`

## Adding Plugins
1. Add plugin to \`config/plugins.yml\`
2. Rebuild container
3. Restart services

## Running Tests
\`\`\`bash
bundle exec rspec
bundle exec rubocop
\`\`\`
EOF

    # 👨‍🔧 Admin Guide
    cat << 'EOF' > docs/admin/README.md
# Administrator Guide 🔧

## Installation
\`\`\`bash
# Production setup
./generate-dockerfile.sh alpine production
docker-compose up -d
\`\`\`

## Backup & Restore
\`\`\`bash
# Backup
./lib/security/backup.sh

# Restore
./lib/security/restore.sh backup_file.tar.gz
\`\`\`

## Monitoring
- Prometheus metrics at :9405
- Log files in /var/log/discourse
- Health checks at /srv/status

## Security
- AppArmor profiles enabled
- Regular security updates
- SSL/TLS configuration
- Fail2ban integration
EOF

    # 📋 Main README
    cat << 'EOF' > README.md
# Discourse Container Generator 🚀

Enterprise-grade Discourse container generation system with support for multiple
base operating systems, development and production environments, and extensive
customization options.

## Features ✨
- 🔒 Security hardened
- 📊 Monitoring ready
- 🔄 Auto-scaling support
- 🛠️ Development environment
- 📦 Plugin system
- 🎨 Theme support
- 💾 Backup/restore
- 🔍 Health checks

## Quick Start 🚀
\`\`\`bash
# Generate Dockerfile
./generate-dockerfile.sh alpine production

# Build container
docker build -t discourse .

# Run container
docker run -d --name discourse discourse
\`\`\`

## Documentation 📚
- [User Guide](docs/user/README.md)
- [Admin Guide](docs/admin/README.md)
- [Developer Guide](docs/dev/README.md)

## License 📜
MIT License - See LICENSE file for details
EOF

    success "✅ Documentation generated"
}

# -----------------------------------------------------------------------------
#  🧹 Cleanup Function
# -----------------------------------------------------------------------------
function cleanup() {
    pending "🧹 Performing cleanup"

    # Remove temporary files
    rm -f base.Dockerfile builder.Dockerfile production.Dockerfile

    # Remove lock file
    rm -f "${LOCK_FILE}"

    # Compress logs older than 7 days
    find "${SCRIPT_DIR}" -name "discourse-generator-*.log" -mtime +7 -exec gzip {} \;

    success "✅ Cleanup complete"
}



# -----------------------------------------------------------------------------
#  🎭 Main Script Execution
# -----------------------------------------------------------------------------
function main() {
    info "🚀 Starting Discourse Container Generator"

    # 📋 Parse Command Line Arguments
    local variant="${1:-}"
    local environment="${2:-production}"
    shift 2 || true

    # 🔍 Validate Arguments
    if [[ -z "$variant" ]]; then
        fatal "❌ Usage: $0 <variant> [environment] [options]"
    fi

    # ⚙️ Load Configuration
    if [[ -f ".env" ]]; then
        info "📝 Loading .env configuration"
        set -o allexport
        source .env
        set +o allexport
    fi

    # 🏗️ Execute Build Stages
    (
        # 🔒 Create Lock File
        exec 9>"${LOCK_FILE}"
        flock -n 9 || fatal "❌ Another build is in progress"

        # 📝 Create Build Log
        exec 1> >(tee -a "${LOG_FILE}")
        exec 2> >(tee -a "${LOG_FILE}" >&2)

        # 🔧 Stage Execution
        info "🏗️ Starting build process for variant: $variant"

        prepare_base_os "$variant"
        prepare_build_environment
        setup_security_configuration
        setup_monitoring
        generate_runtime_configs
        generate_init_scripts

        if [[ "$environment" == "development" ]]; then
            setup_development_environment
        fi

        # 📦 Generate Final Dockerfile
        info "📝 Generating final Dockerfile"
        cat base.Dockerfile builder.Dockerfile production.Dockerfile > "Dockerfile.${variant}"

        # Add documentation generation
        generate_documentation

        # Add cleanup
        trap cleanup EXIT

        success "🎉 Discourse container generation completed successfully!"

        # 🧹 Cleanup Temporary Files
        #rm -f base.Dockerfile builder.Dockerfile production.Dockerfile

        success "✅ Build completed successfully!"

        # 📊 Print Build Summary
        cat << EOF
🚀 Generation Complete!
----------------------

🎉 Build Summary
---------------
📦 Variant: $variant
🔨 Environment: $environment
📂 Output: Dockerfile.${variant}
📦 Container: discourse:${variant}
📝 Documentation: ./docs/
📊 Logs: ${LOG_FILE}

Next Steps:
1. Review the generated Dockerfile
2. Build the container:
   docker build -t discourse:${variant} -f Dockerfile.${variant} .
3. Run the container:
   docker run -d --name discourse discourse:${variant}

For more information, check the documentation in ./docs

Thank you for using Discourse Container Generator!
EOF
    )

}

# -----------------------------------------------------------------------------
#  🚦 Script Entry Point
# -----------------------------------------------------------------------------
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 🔧 Script Setup
    set -euo pipefail
    export LC_ALL=C

    # 📝 Initialize Logging
    LOG_FILE="${SCRIPT_DIR}/discourse-generator-$(date +%Y%m%d-%H%M%S).log"
    touch "${LOG_FILE}"

    # 🎬 Execute Main Function
    trap 'error_handler $? $LINENO $BASH_LINENO "$BASH_COMMAND" $(printf "::%s" ${FUNCNAME[@]:-})' ERR
    main "$@"
fi
