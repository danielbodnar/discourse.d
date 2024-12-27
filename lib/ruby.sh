
#!/usr/bin/env bash
set -euo pipefail

setup_ruby_environment() {
    log "Setting up Ruby environment..."
    
    export RBENV_ROOT="/usr/local/rbenv"
    export PATH="$RBENV_ROOT/bin:$PATH"
    
    git clone --depth 1 https://github.com/rbenv/rbenv.git "$RBENV_ROOT"
    git clone --depth 1 https://github.com/rbenv/ruby-build.git "$RBENV_ROOT/plugins/ruby-build"
    
    eval "$(rbenv init -)"
    
    RUBY_CONFIGURE_OPTS="--disable-install-doc --with-jemalloc" \
    MAKE_OPTS="-j$(nproc)" \
    rbenv install "$RUBY_VERSION"
    rbenv global "$RUBY_VERSION"
    
    gem install bundler -v "$BUNDLER_VERSION"
}
