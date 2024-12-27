#!/usr/bin/env bash
set -euo pipefail

source /usr/lib/discourse/discourse-env

PLUGINS=(
    "discourse-solved"
    "discourse-math"
)

for plugin in "${PLUGINS[@]}"; do
    git clone --depth 1 "https://github.com/discourse/${plugin}.git" "${DISCOURSE_ROOT}/plugins/${plugin}"
    if [ -f "${DISCOURSE_ROOT}/plugins/${plugin}/package.json" ]; then
        (cd "${DISCOURSE_ROOT}/plugins/${plugin}" && yarn install --production)
    fi
    if [ -f "${DISCOURSE_ROOT}/plugins/${plugin}/Gemfile" ]; then
        (cd "${DISCOURSE_ROOT}/plugins/${plugin}" && bundle install)
    fi
done
