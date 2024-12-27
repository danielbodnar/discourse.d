#!/usr/bin/env bash
# dev.sh

# Source nix environment
if ! command -v nix &> /dev/null; then
    echo "Nix is not installed. Please install Nix first."
    exit 1
fi

# Enter development shell
exec nix develop
