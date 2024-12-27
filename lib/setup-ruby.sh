#!/usr/bin/env bash
set -euo pipefail

source /usr/lib/discourse/discourse-env

setup_rbenv() {
    git clone --depth 1 https://github.com/rbenv/rbenv.git "${RBENV_ROOT}"
    git clone --depth 1 https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build"
    
    export PATH="${RBENV_ROOT}/bin:${PATH}"
    eval "$(rbenv init -)"
}

install_ruby() {
    RUBY_CONFIGURE_OPTS="--disable-install-doc --with-jemalloc" \
    MAKE_OPTS="-j$(nproc)" \
    rbenv install "${RUBY_VERSION}"
    rbenv global "${RUBY_VERSION}"
}

setup_bundler() {
    gem install bundler -v "${BUNDLER_VERSION}"
    bundle config set --global deployment true
    bundle config set --global without development:test
    bundle config set --global path vendor/bundle
}

setup_rbenv
install_ruby
setup_bundler
