#!/bin/bash
set -euo pipefail

# Generate melange keys if they don't exist
if [ ! -f melange.rsa ]; then
  docker run --rm -v "${PWD}":/work cgr.dev/chainguard/melange keygen
fi

# Generate apko keys if they don't exist
# if [ ! -f apko.rsa ]; then
#     apko keygen
# fi

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
