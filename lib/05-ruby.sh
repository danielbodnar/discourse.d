
#!/usr/bin/env bash
set -euo pipefail

setup_ruby_environment() {
    log "Setting up Ruby environment..."

    install_rbenv
    install_ruby
    configure_bundler
}

install_rbenv() {
    export RBENV_ROOT="${DISCOURSE_ROOT}/vendor/rbenv"
    git clone --depth 1 https://github.com/rbenv/rbenv.git "${RBENV_ROOT}"
    git clone --depth 1 https://github.com/rbenv/ruby-build.git "${RBENV_ROOT}/plugins/ruby-build"

    # Configure environment
    cat > "${BASE_DIR}/rootfs/base/etc/profile.d/rbenv.sh" << EOF
export RBENV_ROOT="${RBENV_ROOT}"
export PATH="\${RBENV_ROOT}/bin:\${PATH}"
eval "\$(rbenv init -)"
EOF

    source "${BASE_DIR}/rootfs/base/etc/profile.d/rbenv.sh"
}

install_ruby() {
    # Ruby optimization settings
    export RUBY_GC_MALLOC_LIMIT=90000000
    export RUBY_GC_HEAP_FREE_SLOTS=200000
    export RUBY_GC_HEAP_INIT_SLOTS=40000
    export RUBY_GC_HEAP_OLDOBJECT_LIMIT_FACTOR=1.5

    RUBY_CONFIGURE_OPTS="--disable-install-doc --with-jemalloc" \
    MAKE_OPTS="-j$(nproc)" \
    rbenv install "${RUBY_VERSION}"
    rbenv global "${RUBY_VERSION}"
}

configure_bundler() {
    gem install bundler -v "${BUNDLER_VERSION}"
    
    # Configure bundler for deployment
    bundle config --global deployment true
    bundle config --global without development:test
    bundle config --global path "${DISCOURSE_ROOT}/vendor/bundle"
    bundle config --global jobs "$(nproc)"
    bundle config --global retry 3
}
