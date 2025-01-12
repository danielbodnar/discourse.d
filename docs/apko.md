# Discourse Container Build

Project structure:
```
discourse-container/
├── docker-compose.yml
├── melange/
│   ├── ruby.yaml
│   ├── node.yaml
│   ├── discourse.yaml
│   └── configs/
│       └── discourse.conf
├── apko/
│   ├── discourse.yaml
│   └── configs/
│       ├── nginx.conf
│       └── puma.rb
├── scripts/
│   ├── build.sh
│   ├── entrypoint.sh
│   └── setup-dev.sh
└── README.md
```

## Configuration Files

### melange/ruby.yaml
```yaml
package:
  name: ruby-3.2
  version: 3.2.2
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
      - yaml
      - gdbm
      - ncurses

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
      - yaml-dev
      - gdbm-dev
      - ncurses-dev

pipeline:
  - uses: fetch
    with:
      uri: https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz
      expected-sha256: 96c57558871a6748de5bc9f274e93f4b5aad06cd8f37befa0e8d94e7b8a423bc
  - uses: autoconf/configure
    with:
      opts:
        - --prefix=/usr
        - --sysconfdir=/etc
        - --enable-shared
        - --with-openssl
        - --with-readline
        - --with-zlib
        - --with-gmp
  - uses: autoconf/make
    with:
      opts:
        - -j$(nproc)
  - uses: autoconf/make-install
  - uses: strip
```

### melange/node.yaml
```yaml
package:
  name: nodejs
  version: 18.19.0
  epoch: 0
  description: "Node.js JavaScript runtime"
  target-architecture:
    - all
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
      uri: https://nodejs.org/dist/v18.19.0/node-v18.19.0.tar.xz
      expected-sha256: 6127d71df1f9add9a5a47223966d4edca7b0ef5f78c05bd604e465b021e3ee3c
  - uses: autoconf/configure
    with:
      opts:
        - --prefix=/usr
        - --shared-zlib
        - --with-intl=system-icu
  - uses: autoconf/make
    with:
      opts:
        - -j$(nproc)
  - uses: autoconf/make-install
  - uses: strip
```

### melange/discourse.yaml
```yaml
package:
  name: discourse
  version: 3.1.0
  epoch: 0
  description: "Discourse - Open source discussion platform"
  target-architecture:
    - all
  dependencies:
    runtime:
      - ruby-3.2
      - nodejs
      - postgresql15-client
      - imagemagick
      - nginx
      - redis
      - git
      - bash
      - yaml
      - shared-mime-info
      - tzdata
      - libxml2
      - libxslt

environment:
  contents:
    packages:
      - alpine-base
      - build-base
      - ruby-3.2-dev
      - postgresql15-dev
      - imagemagick-dev
      - libxml2-dev
      - libxslt-dev
      - git
      - yarn
      - ruby-bundler

pipeline:
  - name: Setup Discourse
    runs: |
      INSTALL_DIR="${{targets.destdir}}/usr/share/discourse"
      mkdir -p "${INSTALL_DIR}"

      # Clone Discourse
      git clone --branch v3.1.0 https://github.com/discourse/discourse.git "${INSTALL_DIR}"
      cd "${INSTALL_DIR}"

      # Install dependencies
      bundle config set --local deployment true
      bundle config set --local without 'development test'
      bundle install --jobs $(nproc)

      # Install JavaScript dependencies
      yarn install --production

      # Precompile assets
      RAILS_ENV=production bundle exec rake assets:precompile

      # Clean up development files
      rm -rf node_modules tmp/cache spec script/docker test

      # Install configuration files
      install -Dm644 /melange/configs/discourse.conf /etc/discourse/discourse.conf
      install -Dm755 /melange/configs/entrypoint.sh /usr/local/bin/discourse-entrypoint
```

### apko/discourse.yaml
```yaml
contents:
  keyring:
    - https://packages.wolfi.dev/os/wolfi-signing.rsa.pub
  repositories:
    - https://dl-cdn.alpinelinux.org/alpine/edge/main
    - https://dl-cdn.alpinelinux.org/alpine/edge/community
    - /work/packages
  packages:
    - alpine-baselayout
    - discourse
    - ruby-3.2
    - nodejs
    - postgresql15-client
    - nginx
    - redis
    - imagemagick
    - tzdata
    - bash
    - ca-certificates
    - libxml2
    - libxslt
    - shared-mime-info

paths:
  - path: /var/lib/discourse
    type: directory
    uid: 2000
    gid: 2000
    permissions: 0755
  - path: /var/log/discourse
    type: directory
    uid: 2000
    gid: 2000
    permissions: 0755
  - path: /var/tmp/discourse
    type: directory
    uid: 2000
    gid: 2000
    permissions: 0755

accounts:
  groups:
    - groupname: discourse
      gid: 2000
  users:
    - username: discourse
      uid: 2000
      gid: 2000

environment:
  - PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
  - RAILS_ENV=production
  - DISCOURSE_HOSTNAME=localhost
  - DISCOURSE_DB_HOST=postgres
  - DISCOURSE_REDIS_HOST=redis
  - DISCOURSE_DEVELOPER_EMAILS=me@example.com
  - DISCOURSE_SMTP_ADDRESS=smtp.example.com
  - DISCOURSE_SERVE_STATIC_ASSETS=true
  - RUBY_GLOBAL_METHOD_CACHE_SIZE=131072

work-dir: /usr/share/discourse

entrypoint:
  command: /usr/local/bin/discourse-entrypoint

cmd: bundle exec rails server -b 0.0.0.0 -p 3000
```

### docker-compose.yml
```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 5s
      timeout: 3s
      retries: 5

  postgres:
    image: postgres:15-alpine
    environment:
      POSTGRES_USER: discourse
      POSTGRES_PASSWORD: discourse
      POSTGRES_DB: discourse
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U discourse"]
      interval: 5s
      timeout: 3s
      retries: 5

  discourse:
    image: discourse:latest
    build:
      context: .
      dockerfile: Dockerfile
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "3000:3000"
    environment:
      - DISCOURSE_DB_HOST=postgres
      - DISCOURSE_DB_NAME=discourse
      - DISCOURSE_DB_USERNAME=discourse
      - DISCOURSE_DB_PASSWORD=discourse
      - DISCOURSE_REDIS_HOST=redis
      - DISCOURSE_HOSTNAME=localhost
      - RAILS_ENV=production
    volumes:
      - discourse_data:/var/lib/discourse
      - discourse_logs:/var/log/discourse
      - discourse_tmp:/var/tmp/discourse

volumes:
  postgres_data:
  redis_data:
  discourse_data:
  discourse_logs:
  discourse_tmp:
```

### scripts/build.sh
```bash
#!/bin/bash
set -euo pipefail

# Generate melange keys if they don't exist
if [ ! -f melange.rsa ]; then
    melange keygen
fi

# Generate apko keys if they don't exist
if [ ! -f apko.rsa ]; then
    apko keygen
fi

# Build Ruby package
echo "Building Ruby package..."
melange build \
    --signing-key melange.rsa \
    --arch x86_64 \
    melange/ruby.yaml

# Build Node.js package
echo "Building Node.js package..."
melange build \
    --signing-key melange.rsa \
    --arch x86_64 \
    melange/node.yaml

# Build Discourse package
echo "Building Discourse package..."
melange build \
    --signing-key melange.rsa \
    --arch x86_64 \
    melange/discourse.yaml

# Build final image
echo "Building final image..."
apko build \
    --debug \
    apko/discourse.yaml \
    discourse:latest \
    discourse.tar

# Load image into Docker
echo "Loading image into Docker..."
docker load < discourse.tar

echo "Build complete!"
```

### scripts/entrypoint.sh
```bash
#!/bin/bash
set -e

# Wait for PostgreSQL
until pg_isready -h "$DISCOURSE_DB_HOST" -p 5432; do
    echo "Waiting for PostgreSQL..."
    sleep 2
done

# Wait for Redis
until redis-cli -h "$DISCOURSE_REDIS_HOST" ping &>/dev/null; do
    echo "Waiting for Redis..."
    sleep 2
done

# Initialize or migrate database if needed
if [ ! -f /var/lib/discourse/.initialized ]; then
    echo "Initializing Discourse..."
    bundle exec rake db:migrate
    bundle exec rake assets:precompile
    touch /var/lib/discourse/.initialized
else
    echo "Running migrations..."
    bundle exec rake db:migrate
fi

# Start Discourse
exec "$@"
```

## Usage

1. Clone the repository and build the containers:
```bash
git clone <repository>
cd discourse-container
./scripts/build.sh
```

2. Start the services:
```bash
docker-compose up -d
```

3. Create admin user:
```bash
docker-compose exec discourse bundle exec rake admin:create
```

4. Access Discourse at http://localhost:3000

## Notes

- The configuration assumes development/testing setup
- For production, modify environment variables and security settings
- SSL/TLS should be configured for production use
- Backups should be configured for all data volumes
- Monitoring and logging should be set up appropriately
