
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source our libraries
for lib in "${SCRIPT_DIR}/lib"/*.sh; do
    source "$lib"
done

# Template generation
generate_dockerfile() {
    cat << 'EOF'
# Stage 1: Builder
FROM alpine:3.19 AS builder

# Environment variables
ENV DISCOURSE_VERSION=3.2.1 \
    RUBY_VERSION=3.2.2 \
    NODE_VERSION=18.18.0 \
    YARN_VERSION=1.22.19 \
    BUNDLER_VERSION=2.4.22 \
    DISCOURSE_USER=discourse \
    DISCOURSE_GROUP=discourse \
    DISCOURSE_HOME=/home/discourse \
    DISCOURSE_ROOT=/var/www/discourse \
    DISCOURSE_DATA=/var/discourse \
    RAILS_ENV=production

# System packages
RUN apk add --no-cache \
    curl \
    wget \
    git \
    build-base \
    ruby-dev \
    nodejs \
    yarn \
    nginx \
    postgresql-client \
    redis \
    sudo \
    imagemagick-dev \
    libxml2-dev \
    libxslt-dev \
    postgresql-dev \
    yaml-dev \
    zlib-dev \
    && rm -rf /var/cache/apk/*

# Create discourse user
RUN addgroup -S ${DISCOURSE_GROUP} && \
    adduser -S -G ${DISCOURSE_GROUP} -h ${DISCOURSE_HOME} -s /sbin/nologin ${DISCOURSE_USER} && \
    mkdir -p ${DISCOURSE_HOME} ${DISCOURSE_ROOT} ${DISCOURSE_DATA} && \
    chown -R ${DISCOURSE_USER}:${DISCOURSE_GROUP} \
        ${DISCOURSE_HOME} \
        ${DISCOURSE_ROOT} \
        ${DISCOURSE_DATA}

# Copy scripts
COPY rootfs/base/usr/lib/discourse/ /usr/lib/discourse/
RUN chmod +x /usr/lib/discourse/*

# Set up Ruby
RUN /usr/lib/discourse/setup-ruby && \
    /usr/lib/discourse/setup-node

# Clone Discourse
RUN git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git ${DISCOURSE_ROOT}

# Install dependencies
WORKDIR ${DISCOURSE_ROOT}
RUN bundle install --deployment --without development test && \
    yarn install --production && \
    /usr/lib/discourse/install-plugins && \
    RAILS_ENV=production bundle exec rake assets:precompile

# Stage 2: Final image
FROM alpine:3.19

# Copy from builder
COPY --from=builder /usr/local /usr/local
COPY --from=builder ${DISCOURSE_ROOT} ${DISCOURSE_ROOT}
COPY --from=builder ${DISCOURSE_HOME} ${DISCOURSE_HOME}
COPY rootfs/base/etc/ /etc/
COPY rootfs/base/usr/lib/discourse/ /usr/lib/discourse/

# Runtime packages
RUN apk add --no-cache \
    ruby \
    nodejs \
    nginx \
    postgresql-client \
    redis \
    imagemagick \
    && rm -rf /var/cache/apk/*

# Create discourse user
RUN addgroup -S ${DISCOURSE_GROUP} && \
    adduser -S -G ${DISCOURSE_GROUP} -h ${DISCOURSE_HOME} -s /sbin/nologin ${DISCOURSE_USER}

# Volume configuration
VOLUME ["${DISCOURSE_DATA}/shared", \
        "${DISCOURSE_DATA}/uploads", \
        "${DISCOURSE_DATA}/backups", \
        "${DISCOURSE_DATA}/public/assets", \
        "${DISCOURSE_DATA}/plugins", \
        "${DISCOURSE_DATA}/config"]

# Environment setup
ENV RAILS_ENV=production \
    DISCOURSE_HOSTNAME=0.0.0.0

# Ports
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=5m --retries=3 \
    CMD /usr/lib/discourse/health-check

# Set user
USER ${DISCOURSE_USER}

# Working directory
WORKDIR ${DISCOURSE_ROOT}

# Entrypoint and command
ENTRYPOINT ["/usr/lib/discourse/discourse-init"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
EOF
}

# Main execution
main() {
    generate_dockerfile > "Dockerfile"
}

main "$@"
