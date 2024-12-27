# tools/lib/logging.sh
#!/usr/bin/env bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    local level="$1"
    local color="$2"
    shift 2
    echo -e "${color}[$(date -u '+%Y-%m-%d %H:%M:%S')] [$level] $*${NC}" >&2
}

# Function to log debug messages
debug() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        log "DEBUG" "$BLUE" "$@"
    fi
}

# Function to log info messages
info() {
    if [[ "${VERBOSE:-false}" == "true" ]]; then
        log "INFO" "$GREEN" "$@"
    fi
}

# Function to log warning messages
warn() {
    log "WARN" "$YELLOW" "$@"
}

# Function to log error messages
error() {
    log "ERROR" "$RED" "$@"
    exit 1
}

# Function to log success messages
success() {
    log "SUCCESS" "$GREEN" "$@"
}

# Function to enable debug output for commands
enable_debug_output() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        set -x
    fi
}

# Function to disable debug output for commands
disable_debug_output() {
    if [[ "${DEBUG:-false}" == "true" ]]; then
        set +x
    fi
}
