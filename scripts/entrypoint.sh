#!/bin/bash
set -e

# Setup function
setup_environment() {
    # Ensure workspace permissions
    sudo chown -R $(id -u):$(id -g) /workspace

    # Create necessary directories if they don't exist
    mkdir -p /workspace/{build,output}

    # Initialize git if needed
    if [ ! -d "/workspace/.git" ]; then
        git init
    fi
}

# Main
setup_environment

# Execute passed command
exec "$@"