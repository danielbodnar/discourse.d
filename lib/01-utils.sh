
#!/usr/bin/env bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging functions
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Validation functions
validate_environment() {
    local required_commands=(
        "git"
        "mkosi"
        "systemd-nspawn"
        "systemctl"
    )
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            error "Required command not found: $cmd"
        fi
    done
}

# Helper functions
create_user() {
    local user="$1"
    local uid="$2"
    local group="$3"
    local gid="$4"
    
    if ! getent group "$group" >/dev/null; then
        groupadd -g "$gid" "$group"
    fi
    
    if ! getent passwd "$user" >/dev/null; then
        useradd -u "$uid" -g "$gid" -d "/discourse" -s "/sbin/nologin" "$user"
    fi
}
