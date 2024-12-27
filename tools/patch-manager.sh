#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="${SCRIPT_DIR}/../patches"
PATCH_LOG="${PATCH_DIR}/.applied_patches"

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

init_patch_system() {
    mkdir -p "${PATCH_DIR}"
    touch "${PATCH_LOG}"
}

is_patch_applied() {
    local patch_file="$1"
    grep -q "^${patch_file}$" "${PATCH_LOG}" 2>/dev/null
}

apply_patch() {
    local patch_file="$1"
    local full_path="${PATCH_DIR}/${patch_file}"
    
    if ! [ -f "${full_path}" ]; then
        error "Patch file not found: ${patch_file}"
    fi
    
    if is_patch_applied "${patch_file}"; then
        warn "Patch already applied: ${patch_file}"
        return 0
    fi
    
    log "Applying patch: ${patch_file}"
    if git apply --check --verbose "${full_path}" >/dev/null 2>&1; then
        if git apply --apply --verbose "${full_path}"; then
            echo "${patch_file}" >> "${PATCH_LOG}"
            success "Successfully applied: ${patch_file}"
        else
            error "Failed to apply patch: ${patch_file}"
        fi
    else
        error "Patch validation failed: ${patch_file}"
    fi
}

apply_all_patches() {
    local patches=("${PATCH_DIR}"/*.patch)
    if [ ${#patches[@]} -eq 0 ]; then
        warn "No patches found in ${PATCH_DIR}"
        return 0
    fi
    
    for patch in "${patches[@]}"; do
        apply_patch "$(basename "${patch}")"
    done
}

show_status() {
    log "Patch Status:"
    echo "----------------------------------------"
    for patch in "${PATCH_DIR}"/*.patch; do
        local patch_name="$(basename "${patch}")"
        if is_patch_applied "${patch_name}"; then
            echo -e "${GREEN}[✓]${NC} ${patch_name}"
        else
            echo -e "${RED}[✗]${NC} ${patch_name}"
        fi
    done
    echo "----------------------------------------"
}

case "${1:-}" in
    "init") init_patch_system ;;
    "apply") shift; apply_patch "$1" ;;
    "apply-all") apply_all_patches ;;
    "status") show_status ;;
    *) echo "Usage: $0 {init|apply <patch>|apply-all|status}" ;;
esac
