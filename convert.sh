#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source our modules
source "${SCRIPT_DIR}/lib/00-config.sh"
source "${SCRIPT_DIR}/lib/01-utils.sh"
source "${SCRIPT_DIR}/lib/02-structure.sh"

main() {
    log "Starting Discourse conversion..."

    validate_environment
    create_directory_structure
    setup_volume_links
    generate_volume_systemd_mount_units
    generate_volume_tmpfiles
    setup_backup_system
    success "Initial setup completed successfully!"
}

main "$@"