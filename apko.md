#!/bin/bash
# discourse_scaffold.sh
# Generates an apko/melange project structure for Discourse

set -euo pipefail

# Configuration
DISCOURSE_VERSION="3.1.0.beta4"
RUBY_VERSION="3.2.2"
NODE_VERSION="18.19.0"
PROJECT_ROOT="${1:-discourse-apko}"
GITHUB_REPO="discourse/discourse"

# Create project structure
mkdir -p "${PROJECT_ROOT}"/{melange,apko}/{configs,keys}
mkdir -p "${PROJECT_ROOT}/workspace"

# Generate melange keyring
if [ ! -f "${PROJECT_ROOT}/melange/keys/melange.rsa" ]; then
    melange keygen "${PROJECT_ROOT}/melange/keys/melange.rsa"
fi

# Generate apko keyring
if [ ! -f "${PROJECT_ROOT}/apko/keys/apko.rsa" ]; then
    apko keygen "${PROJECT_ROOT}/apko/keys/apko.rsa"
fi

# Create base package definitions for Ruby dependencies
cat > "${PROJECT_ROOT}/melange/configs/ruby.yaml" <<EOF
package:
  name: ruby
  version: ${RUBY_VERSION}
  epoch: 0
  description: "Ruby programming language"
  target-architecture:
    - all
  copyright:
    - paths:
      - "*"
      attestation: |
        Copyright 1993-2023 Yukihiro Matsumoto
      license: Ruby
  dependencies:
    runtime:
      - busybox
      - ca-certificates
      - gmp
      - libffi
      - libgcc
      - libstdc++
      - openssl
      - readline
      - zlib

environment:
  contents:
    packages:
      - alpine-base
      - build-base
      - linux-headers
      - openssl-dev
      - readline-dev
      - zlib-dev
      - gmp-dev
      - libffi-dev

pipeline:
  - uses: fetch
    with:
      uri: https://cache.ruby-lang.org/pub/ruby/${RUBY_VERSION%.*}/ruby-$RUBY_VERSION.tar.gz
      expected-sha256: ~~~ # Add correct SHA256 here
  - uses: autoconf/configure
    with:
      opts:
        - --prefix=/usr
        - --sysconfdir=/etc
        - --enable-shared
  - uses: autoconf/make
    with:
      opts:
        - -j\${{targets.ncpu}}
  - uses: autoconf/make-install
  - uses: strip
EOF

# Create Node.js package definition
cat > "${PROJECT_ROOT}/melange/configs/nodejs.yaml" <<EOF
package:
  name: nodejs
  version: ${NODE_VERSION}
  epoch: 0
  description: "Node.js JavaScript runtime"
  target-architecture:
    - all
  copyright:
    - paths:
      - "*"
      attestation: |
        Copyright Node.js contributors. All rights reserved.
      license: MIT
  dependencies:
    runtime:
      - busybox
      - ca-certificates
      - libgcc
      - libstdc++

environment:
  contents:
    packages:
      - alpine-base
      - build-base
      - python3
      - linux-headers

pipeline:
  - uses: fetch
    with:
      uri: https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}.tar.gz
      expected-sha256: ~~~ # Add correct SHA256 here
  - uses: autoconf/configure
    with:
      opts:
        - --prefix=/usr
  - uses: autoconf/make
    with:
      opts:
        - -j\${{targets.ncpu}}
  - uses: autoconf/make-install
  - uses: strip
EOF

# Create Discourse package definition
cat > "${PROJECT_ROOT}/melange/configs/discourse.yaml" <<EOF
package:
  name: discourse
  version: ${DISCOURSE_VERSION}
  epoch: 0
  description: "Discourse - Open source discussion platform"
  target-architecture:
    - all
  copyright:
    - paths:
      - "*"
      attestation: |
        Copyright (c) 2014-2023 Civilized Discourse Construction Kit, Inc.
      license: GPL-2.0
  dependencies:
    runtime:
      - ruby
      - nodejs
      - postgresql-client
      - imagemagick
      - nginx
      - redis
      - git
      - bash
      - yarn

environment:
  contents:
    packages:
      - alpine-base
      - build-base
      - ruby-dev
      - nodejs
      - postgresql-dev
      - imagemagick-dev
      - git

pipeline:
  - uses: git-checkout
    with:
      repository: ${GITHUB_REPO}
      tag: v${DISCOURSE_VERSION}
      destination: /discourse
  - uses: ruby/bundle-install
    with:
      gemfile: /discourse/Gemfile
      without:
        - development
        - test
  - runs: |
      cd /discourse
      RAILS_ENV=production bundle exec rake assets:precompile
  - uses: install
    with:
      source: /discourse
      destination: /usr/share/discourse
EOF

# Create apko configuration for final image
cat > "${PROJECT_ROOT}/apko/configs/discourse.yaml" <<EOF
contents:
  repositories:
    - https://dl-cdn.alpinelinux.org/alpine/edge/main
    - https://dl-cdn.alpinelinux.org/alpine/edge/community
    - '@local /workspace/packages'
  keyring:
    - /etc/apk/keys/alpine-devel@lists.alpinelinux.org-616ae350.rsa.pub
    - /workspace/keys/melange.rsa.pub
  packages:
    - alpine-base
    - discourse
    - nginx
    - postgresql-client
    - redis
    - bash
    - su-exec

accounts:
  groups:
    - groupname: discourse
      gid: 2000
  users:
    - username: discourse
      uid: 2000
      gid: 2000

paths:
  - path: /var/lib/discourse
    type: directory
    permissions: 0755
    uid: 2000
    gid: 2000
  - path: /var/log/discourse
    type: directory
    permissions: 0755
    uid: 2000
    gid: 2000

environment:
  RAILS_ENV: "production"
  DISCOURSE_HOSTNAME: "discourse.local"

work-dir: /usr/share/discourse

entrypoint:
  command: /usr/bin/discourse-entrypoint.sh

cmd: bundle exec rails server -b 0.0.0.0
EOF

# Create entrypoint script
cat > "${PROJECT_ROOT}/workspace/discourse-entrypoint.sh" <<'EOF'
#!/bin/bash
set -e

# Wait for PostgreSQL
until pg_isready -h $POSTGRES_HOST -p ${POSTGRES_PORT:-5432}; do
    echo "Waiting for PostgreSQL to be ready..."
    sleep 2
done

# Wait for Redis
until redis-cli -h $REDIS_HOST ping &>/dev/null; do
    echo "Waiting for Redis to be ready..."
    sleep 2
done

# Initialize database if needed
if [ ! -f /var/lib/discourse/.initialized ]; then
    echo "Initializing Discourse database..."
    bundle exec rake db:migrate
    bundle exec rake assets:precompile
    touch /var/lib/discourse/.initialized
fi

# Start Discourse
exec "$@"
EOF
chmod +x "${PROJECT_ROOT}/workspace/discourse-entrypoint.sh"

# Create build script
cat > "${PROJECT_ROOT}/build.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

# Build Ruby package
melange build \
    --signing-key melange/keys/melange.rsa \
    --pipeline-cache-dir .cache \
    melange/configs/ruby.yaml

# Build Node.js package
melange build \
    --signing-key melange/keys/melange.rsa \
    --pipeline-cache-dir .cache \
    melange/configs/nodejs.yaml

# Build Discourse package
melange build \
    --signing-key melange/keys/melange.rsa \
    --pipeline-cache-dir .cache \
    melange/configs/discourse.yaml

# Build final image
apko build \
    --debug \
    apko/configs/discourse.yaml \
    discourse:latest \
    discourse.tar
EOF
chmod +x "${PROJECT_ROOT}/build.sh"

# Create README
cat > "${PROJECT_ROOT}/README.md" <<EOF
# Discourse Apko/Melange Project

This project contains the necessary configurations to build a Discourse container image
using apko and melange.

## Prerequisites

- apko
- melange
- docker (for testing)

## Building

1. Generate keys (if not already done):
   \`\`\`bash
   melange keygen melange/keys/melange.rsa
   apko keygen apko/keys/apko.rsa
   \`\`\`

2. Build the image:
   \`\`\`bash
   ./build.sh
   \`\`\`

## Running

1. Set up environment variables:
   \`\`\`bash
   export POSTGRES_HOST=localhost
   export POSTGRES_PORT=5432
   export REDIS_HOST=localhost
   export DISCOURSE_HOSTNAME=discourse.local
   \`\`\`

2. Run the container:
   \`\`\`bash
   docker load < discourse.tar
   docker run -d \\
       --name discourse \\
       -p 3000:3000 \\
       -e POSTGRES_HOST=\${POSTGRES_HOST} \\
       -e POSTGRES_PORT=\${POSTGRES_PORT} \\
       -e REDIS_HOST=\${REDIS_HOST} \\
       -e DISCOURSE_HOSTNAME=\${DISCOURSE_HOSTNAME} \\
       discourse:latest
   \`\`\`

## Configuration

The following environment variables are available:

- \`POSTGRES_HOST\`: PostgreSQL host
- \`POSTGRES_PORT\`: PostgreSQL port (default: 5432)
- \`REDIS_HOST\`: Redis host
- \`DISCOURSE_HOSTNAME\`: Discourse hostname

## Directory Structure

- \`melange/configs/\`: Melange package definitions
- \`apko/configs/\`: Apko image configurations
- \`workspace/\`: Build workspace and scripts
EOF

echo "Project scaffolded in ${PROJECT_ROOT}"
echo "Review and update SHA256 hashes in melange configs before building"
echo "Run './build.sh' to build packages and final image"