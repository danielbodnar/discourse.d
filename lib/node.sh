
#!/usr/bin/env bash
set -euo pipefail

setup_nodejs_environment() {
    log "Setting up Node.js environment..."
    
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.gz" | \
        tar -xz -C /usr/local --strip-components=1
    
    npm install -g yarn@"$YARN_VERSION"
}
