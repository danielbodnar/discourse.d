#!/usr/bin/env bash
set -euo pipefail

# Pull base images
docker pull alpine:3.19
docker pull ruby:3.2.2-alpine3.19
docker pull node:18.18.0-alpine3.19

# Tag images for local use
docker tag alpine:3.19 discourse-base:latest
docker tag ruby:3.2.2-alpine3.19 discourse-ruby:latest
docker tag node:18.18.0-alpine3.19 discourse-node:latest
