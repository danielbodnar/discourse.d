
#!/usr/bin/env bash

install_discourse() {
    log "Installing Discourse..."
    
    cd "${DISCOURSE_ROOT}"
    bundle install --deployment --without test development
    yarn install --production
    RAILS_ENV=production bundle exec rake assets:precompile
}

configure_discourse() {
    log "Configuring Discourse..."
    
    # Initialize database if needed
    RAILS_ENV=production bundle exec rake db:migrate
    
    # Install plugins
    if [ -n "${DISCOURSE_PLUGINS}" ]; then
        for plugin in ${DISCOURSE_PLUGINS//,/ }; do
            install_plugin "$plugin"
        done
    fi
}

install_plugin() {
    local plugin="$1"
    local plugin_name=$(basename "$plugin" .git)
    
    if [ ! -d "${DISCOURSE_ROOT}/plugins/${plugin_name}" ]; then
        git clone "$plugin" "${DISCOURSE_ROOT}/plugins/${plugin_name}"
        if [ -f "${DISCOURSE_ROOT}/plugins/${plugin_name}/package.json" ]; then
            (cd "${DISCOURSE_ROOT}/plugins/${plugin_name}" && yarn install --production)
        fi
        if [ -f "${DISCOURSE_ROOT}/plugins/${plugin_name}/Gemfile" ]; then
            (cd "${DISCOURSE_ROOT}/plugins/${plugin_name}" && bundle install)
        fi
    fi
}
