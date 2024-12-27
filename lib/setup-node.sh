#!/usr/bin/env bash
set -euo pipefail

source /usr/lib/discourse/discourse-env

# Download and extract Node.js
curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" | \
    tar -xz --strip-components=1 -C /usr/local

# Install Yarn
npm install -g yarn@${YARN_VERSION}

# Configure Yarn
yarn config set --global production true
