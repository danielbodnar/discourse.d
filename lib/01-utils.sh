#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

validate_environment() {
    log "Validating environment..."
    
    # Check for required commands
    for cmd in git mkosi systemd-nspawn; do
        if ! command -v "$cmd" >/dev/null; then
            error "Required command not found: $cmd"
        fi
    done
    
    success "Environment validation passed"
}
