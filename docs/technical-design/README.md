# Discourse Alpine Migration Technical Design Document

## 1. Introduction
This document outlines the technical design for migrating Discourse from the Bitnami container to a clean Alpine 3.19 implementation. The focus is on creating a secure, maintainable container with proper volume management, unprivileged execution, and readOnlyRootFilesystem compliance.

## 2. Prerequisites and Dependencies
- Alpine 3.19 base image
- Ruby 3.2.2 with rbenv
- Node.js 18.18.0
- PostgreSQL client
- Redis client
- ImageMagick with security policies
- Build essentials (build-base, git, etc.)

<details>
<summary>Installation Script</summary>

```bash
#!/bin/bash
set -euo pipefail

# Install base system dependencies
apk add --no-cache \
    build-base \
    git \
    curl \
    linux-headers \
    libxml2-dev \
    libxslt-dev \
    postgresql-dev \
    imagemagick-dev \
    yaml-dev \
    zlib-dev \
    readline-dev \
    openssl-dev \
    nginx \
    sudo \
    bash

# Create discourse user/group
addgroup -S discourse
adduser -S -G discourse discourse

# Set up directory structure
mkdir -p /var/www/discourse \
    /home/discourse \
    /var/discourse/{shared,uploads,backups,public/assets,plugins,config}

# Set up rbenv
git clone --depth 1 https://github.com/rbenv/rbenv.git /usr/local/rbenv
git clone --depth 1 https://github.com/rbenv/ruby-build.git /usr/local/rbenv/plugins/ruby-build

# Configure environment
cat > /etc/profile.d/rbenv.sh << 'EOF'
export RBENV_ROOT="/usr/local/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"
EOF

# Install Ruby
source /etc/profile.d/rbenv.sh
RUBY_CONFIGURE_OPTS="--disable-install-doc --with-jemalloc" \
MAKE_OPTS="-j$(nproc)" \
rbenv install ${RUBY_VERSION:-3.2.2}
rbenv global ${RUBY_VERSION:-3.2.2}

# Install Node.js
curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION:-18.18.0}/node-v${NODE_VERSION:-18.18.0}-linux-x64.tar.gz" | \
    tar -xz -C /usr/local --strip-components=1

# Set permissions
chown -R discourse:discourse \
    /var/www/discourse \
    /home/discourse \
    /var/discourse
```
</details>

## 3. Configuration Options
The configuration system uses a hierarchical approach with base settings and overrides.

<details>
<summary>Configuration Schema</summary>

```typescript
interface DiscourseConfig {
  // Core Settings
  core: {
    hostname: string;
    title: string;
    developerEmails: string[];
    environment: "production" | "development";
    rootPath: string;
    dataPath: string;
  };

  // Database Configuration
  database: {
    host: string;
    port: number;
    name: string;
    username: string;
    password: string;
    poolSize: number;
  };

  // Redis Configuration
  redis: {
    host: string;
    port: number;
    password?: string;
    db: number;
  };

  // S3 Configuration
  s3?: {
    enabled: boolean;
    bucket: string;
    accessKey: string;
    secretKey: string;
    region: string;
    endpoint?: string;
    cdnUrl?: string;
  };

  // SMTP Configuration
  smtp?: {
    enabled: boolean;
    address: string;
    port: number;
    username?: string;
    password?: string;
    startTls: boolean;
  };

  // Security Configuration
  security: {
    forceHttps: boolean;
    enableCors: boolean;
    corsOrigin?: string;
    maxReqsPerIp: number;
    maxUserApiReqs: number;
  };

  // Volume Configuration
  volumes: {
    shared: string;
    uploads: string;
    backups: string;
    assets: string;
    plugins: string;
    config: string;
  };

  // Container Configuration
  container: {
    user: string;
    group: string;
    uid: number;
    gid: number;
    readOnlyRoot: boolean;
    memoryLimit: string;
    cpuLimit: string;
  };
}
```
</details>

## 4. Implementation Steps
1. Create base Alpine image with required dependencies
2. Set up directory structure and permissions
3. Install and configure Ruby environment using rbenv
4. Install Node.js and Yarn
5. Clone and configure Discourse application
6. Set up volume mounts and permissions
7. Configure nginx as reverse proxy
8. Implement S3 backup functionality
9. Set up security policies
10. Create production Dockerfile
11. Create development environment

## 5. Templated Implementation
```dockerfile
# Build stage
FROM alpine:3.19 AS builder

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    git \
    curl \
    linux-headers \
    libxml2-dev \
    libxslt-dev \
    postgresql-dev \
    imagemagick-dev \
    yaml-dev \
    zlib-dev \
    readline-dev \
    openssl-dev

# Set up Ruby
COPY rootfs/usr/local/rbenv /usr/local/rbenv
ENV RBENV_ROOT="/usr/local/rbenv"
ENV PATH="$RBENV_ROOT/bin:$PATH"
RUN eval "$(rbenv init -)" && \
    rbenv install ${RUBY_VERSION} && \
    rbenv global ${RUBY_VERSION}

# Install Node.js
COPY rootfs/usr/local/node /usr/local/
ENV PATH="/usr/local/node/bin:$PATH"

# Build Discourse
WORKDIR /var/www/discourse
COPY rootfs/var/www/discourse .
RUN bundle install --deployment --without development test && \
    yarn install --production && \
    RAILS_ENV=production bundle exec rake assets:precompile

# Final stage
FROM alpine:3.19

# Copy rootfs
COPY rootfs/ /
COPY --from=builder /var/www/discourse /var/www/discourse

# Configure environment
ENV RAILS_ENV=production
ENV DISCOURSE_HOSTNAME=localhost
ENV PATH="/usr/local/rbenv/shims:/usr/local/rbenv/bin:$PATH"

USER discourse
EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
```

## 6. Next Steps and Roadmap
1. Implement CI/CD pipeline
2. Add monitoring and logging
3. Create Helm charts for Kubernetes deployment
4. Add automated backup system
5. Implement plugin management system
6. Create migration tools from Bitnami
7. Add development environment tooling
8. Create comprehensive test suite

## 7. References
1. [Discourse GitHub Repository](https://github.com/discourse/discourse)
2. [Bitnami Discourse Container](https://github.com/bitnami/containers/tree/main/bitnami/discourse)
3. [Alpine Linux Packages](https://pkgs.alpinelinux.org/)
4. [rbenv Documentation](https://github.com/rbenv/rbenv)