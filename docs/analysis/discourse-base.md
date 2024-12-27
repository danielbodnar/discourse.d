# Discourse Docker Images Analysis (v3.2.1)

## 1. discourse/base Image
Base image for production Discourse deployments.

### Dockerfile Analysis
```dockerfile
FROM ubuntu:22.04

# Build arguments
ARG RUBY_VERSION=3.2.2
ARG NODE_VERSION=18.18.0
ARG DISCOURSE_VERSION=3.2.1

# Environment setup
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    RAILS_ENV=production \
    DEBIAN_FRONTEND=noninteractive

# System packages
RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    curl \
    libxslt1-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libyaml-dev \
    libxml2-dev \
    libpq-dev \
    gawk \
    imagemagick \
    advancecomp \
    gifsicle \
    jhead \
    jpegoptim \
    libjpeg-progs \
    optipng \
    pngcrush \
    pngquant \
    brotli \
    && rm -rf /var/lib/apt/lists/*

# Ruby installation
RUN curl -sSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash && \
    echo 'export PATH="/root/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc && \
    . ~/.bashrc && \
    rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION && \
    gem install bundler --version '~> 2.4.22'

# Node.js installation
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g yarn

# Discourse installation
RUN git clone --branch v${DISCOURSE_VERSION} https://github.com/discourse/discourse.git /var/www/discourse && \
    cd /var/www/discourse && \
    bundle install --deployment --without development test && \
    yarn install --production && \
    bundle exec rake assets:precompile
```

### Key Scripts

#### discourse-setup
```bash
#!/bin/bash
# /usr/local/bin/discourse-setup

set -e

# Create discourse user
adduser --disabled-password --gecos "" discourse

# Configure directories
mkdir -p /var/www/discourse/{public,tmp}
mkdir -p /var/www/discourse/public/{backups,uploads}
mkdir -p /var/www/discourse/tmp/{pids,sockets}

# Set permissions
chown -R discourse:discourse /var/www/discourse

# Configure environment
cat > /etc/discourse/discourse.conf << EOF
db_host = ${DISCOURSE_DB_HOST:-localhost}
db_port = ${DISCOURSE_DB_PORT:-5432}
db_name = ${DISCOURSE_DB_NAME:-discourse}
db_username = ${DISCOURSE_DB_USERNAME:-discourse}
db_password = ${DISCOURSE_DB_PASSWORD:-discourse}
redis_host = ${DISCOURSE_REDIS_HOST:-localhost}
redis_port = ${DISCOURSE_REDIS_PORT:-6379}
EOF
```

## 2. discourse_dev Image
Development environment image with additional tools and configurations.

### Dockerfile Analysis
```dockerfile
FROM discourse/base:3.2.1

# Switch to development environment
ENV RAILS_ENV=development

# Install development packages
RUN apt-get update && apt-get install -y \
    vim \
    postgresql \
    redis-server \
    sqlite3 \
    libsqlite3-dev \
    chrome-browser \
    && rm -rf /var/lib/apt/lists/*

# Install development gems
WORKDIR /var/www/discourse
RUN bundle install --with development test && \
    yarn install

# Development user setup
RUN useradd -m -s /bin/bash developer && \
    echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R developer:developer /var/www/discourse

USER developer
```

## 3. Devcontainer Configuration
Located in `.devcontainer/devcontainer.json`

```json
{
  "name": "Discourse Development",
  "dockerFile": "../Dockerfile.dev",
  "context": "..",

  "settings": {
    "terminal.integrated.shell.linux": "/bin/bash",
    "ruby.useBundler": true,
    "ruby.useLanguageServer": true,
    "ruby.lint": {
      "rubocop": true
    },
    "ruby.format": "rubocop"
  },

  "extensions": [
    "rebornix.ruby",
    "castwide.solargraph",
    "eamodio.gitlens",
    "dbaeumer.vscode-eslint"
  ],

  "forwardPorts": [3000, 5432, 6379],

  "postCreateCommand": "bundle install && yarn install",

  "remoteUser": "developer",

  "mounts": [
    "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.gitconfig,target=/home/developer/.gitconfig,type=bind"
  ],

  "containerEnv": {
    "RAILS_ENV": "development",
    "DISCOURSE_DEV_DB_USERNAME": "developer",
    "DISCOURSE_DEV_DB_PASSWORD": "discourse",
    "DISCOURSE_DEV_DB_NAME": "discourse_development"
  }
}
```

### Development Environment Variables
```bash
# .env.development
DISCOURSE_DEV_DB_USERNAME=developer
DISCOURSE_DEV_DB_PASSWORD=discourse
DISCOURSE_DEV_DB_NAME=discourse_development
DISCOURSE_DEV_REDIS_HOST=localhost
DISCOURSE_DEV_REDIS_PORT=6379
DISCOURSE_DEV_HOSTNAME=localhost
DISCOURSE_DEV_PORT=3000
```

## 4. Development Scripts

### setup-dev.sh
```bash
#!/bin/bash
# /usr/local/bin/setup-dev

set -e

# Install development dependencies
bundle install
yarn install

# Setup development database
bundle exec rake db:create
bundle exec rake db:migrate
bundle exec rake db:seed_fu

# Install plugins
bundle exec rake plugin:install_all_gems
```

### test-setup.sh
```bash
#!/bin/bash
# /usr/local/bin/test-setup

set -e

# Setup test database
RAILS_ENV=test bundle exec rake db:create
RAILS_ENV=test bundle exec rake db:migrate

# Run tests
bundle exec rspec
```

## 5. Volume Structure
```plaintext
/var/www/discourse/
├── public/
│   ├── uploads/
│   ├── backups/
│   └── assets/
├── tmp/
│   ├── pids/
│   └── sockets/
├── log/
└── plugins/
```

## 6. Development Tools Configuration

### database.yml
```yaml
development:
  adapter: postgresql
  database: <%= ENV['DISCOURSE_DEV_DB_NAME'] %>
  username: <%= ENV['DISCOURSE_DEV_DB_USERNAME'] %>
  password: <%= ENV['DISCOURSE_DEV_DB_PASSWORD'] %>
  host: localhost
  pool: 5

test:
  adapter: postgresql
  database: discourse_test
  username: <%= ENV['DISCOURSE_DEV_DB_USERNAME'] %>
  password: <%= ENV['DISCOURSE_DEV_DB_PASSWORD'] %>
  host: localhost
  pool: 5
```

### redis.yml
```yaml
development:
  host: <%= ENV['DISCOURSE_DEV_REDIS_HOST'] %>
  port: <%= ENV['DISCOURSE_DEV_REDIS_PORT'] %>
  db: 0

test:
  host: localhost
  port: 6379
  db: 1
```

## 7. Development Dependencies
```json
{
  "devDependencies": {
    "@babel/core": "^7.16.0",
    "@babel/preset-env": "^7.16.0",
    "babel-loader": "^8.2.3",
    "eslint": "^8.2.0",
    "prettier": "^2.4.1",
    "webpack": "^5.64.0",
    "webpack-cli": "^4.9.1"
  }
}
```

## 8. VS Code Tasks
```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Rails Server",
      "type": "shell",
      "command": "bundle exec rails server -b 0.0.0.0",
      "group": "none",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    },
    {
      "label": "Sidekiq",
      "type": "shell",
      "command": "bundle exec sidekiq",
      "group": "none",
      "presentation": {
        "reveal": "always",
        "panel": "new"
      }
    }
  ]
}
```
