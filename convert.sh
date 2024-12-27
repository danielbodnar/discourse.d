
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
    
    validate_environment
    create_directory_structure
    setup_volume_links
    generate_volume_systemd_mount_units
    generate_volume_tmpfiles
    
    success "Initial setup completed successfully!"
}

# Execute main function
main "$@"
