#!/bin/bash
set -euo pipefail

# Environment
source /usr/lib/discourse/discourse-env

# Initialize database if needed
initialize_database() {
    if ! discourse eval "Post.exists?"; then
        log "Initializing database..."
        discourse db:migrate
        discourse db:seed_fu
    fi
}

# Configure Discourse settings
configure_discourse() {
    log "Configuring Discourse..."

    # Update site settings
    discourse eval "SiteSetting.title = '${DISCOURSE_TITLE}'"
    discourse eval "SiteSetting.site_description = '${DISCOURSE_DESCRIPTION}'"
    discourse eval "SiteSetting.contact_email = '${DISCOURSE_CONTACT_EMAIL}'"
    discourse eval "SiteSetting.notification_email = '${DISCOURSE_NOTIFICATION_EMAIL}'"

    # Configure SMTP if enabled
    if [ "${DISCOURSE_SMTP_ENABLED}" = "true" ]; then
        discourse eval "SiteSetting.smtp_address = '${DISCOURSE_SMTP_ADDRESS}'"
        discourse eval "SiteSetting.smtp_port = ${DISCOURSE_SMTP_PORT}"
        discourse eval "SiteSetting.smtp_user_name = '${DISCOURSE_SMTP_USER}'"
        discourse eval "SiteSetting.smtp_password = '${DISCOURSE_SMTP_PASSWORD}'"
    fi
}

# Install plugins
install_plugins() {
    log "Installing plugins..."
    for plugin in ${DISCOURSE_PLUGINS//,/ }; do
        plugin_name=$(basename $plugin .git)
        if [ ! -d "${DISCOURSE_ROOT}/plugins/${plugin_name}" ]; then
            git clone $plugin "${DISCOURSE_ROOT}/plugins/${plugin_name}"
            if [ -f "${DISCOURSE_ROOT}/plugins/${plugin_name}/package.json" ]; then
                (cd "${DISCOURSE_ROOT}/plugins/${plugin_name}" && yarn install --production)
            fi
            if [ -f "${DISCOURSE_ROOT}/plugins/${plugin_name}/Gemfile" ]; then
                (cd "${DISCOURSE_ROOT}/plugins/${plugin_name}" && bundle install)
            fi
        fi
    done
}

# Main
main() {
    initialize_database
    configure_discourse
    install_plugins
}

main "$@"