#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source all library files in order
for lib in "${SCRIPT_DIR}/lib"/*.sh; do
    source "$lib"
done

# Main execution
main() {
    log "Starting Discourse conversion setup..."

    create_directory_structure
    generate_mkosi_config
    generate_distribution_vars
    generate_systemd_service
    setup_ruby_environment
    setup_nodejs_environment
    setup_discourse
    generate_nginx_config
    generate_dockerfile
    generate_docker_compose
    generate_build_script

    success "Discourse conversion setup completed successfully!"
    show_next_steps
}

# Execute main function
main "$@"