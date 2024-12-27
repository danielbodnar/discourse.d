
#!/usr/bin/env bash

# Project Configuration
PROJECT_NAME="discourse"
BASE_DIR="$(pwd)/${PROJECT_NAME}-conversion"

# Distribution Configuration
DISTRIBUTIONS=(
    "alpine"
    "arch"
    "debian"
    "ubuntu"
)

# Version Configuration
DISCOURSE_VERSION="${DISCOURSE_VERSION:-3.2.1}"
DISCOURSE_REPO="https://github.com/discourse/discourse.git"
RUBY_VERSION="${RUBY_VERSION:-3.2.2}"
NODE_VERSION="${NODE_VERSION:-18.18.0}"
BUNDLER_VERSION="${BUNDLER_VERSION:-2.4.22}"
YARN_VERSION="${YARN_VERSION:-1.22.19}"

# Discourse Paths
DISCOURSE_HOME="/home/discourse"
DISCOURSE_ROOT="/var/www/discourse"
DISCOURSE_DATA="/var/discourse"

# User/Group settings
DISCOURSE_USER="discourse"
DISCOURSE_GROUP="discourse"
DISCOURSE_UID="999"
DISCOURSE_GID="999"
