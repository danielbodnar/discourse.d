
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PATCH_DIR="${SCRIPT_DIR}/../patches"
PATCH_LOG="${PATCH_DIR}/.applied_patches"

# Initialize patch system
init_patch_system() {
    mkdir -p "${PATCH_DIR}"
    touch "${PATCH_LOG}"
}

# Check if patch is already applied
is_patch_applied() {
    local patch_file="$1"
    grep -q "^${patch_file}$" "${PATCH_LOG}" 2>/dev/null
}

# Apply a patch
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
    if git apply --check "${full_path}" >/dev/null 2>&1; then
        if git apply "${full_path}"; then
            echo "${patch_file}" >> "${PATCH_LOG}"
            success "Successfully applied: ${patch_file}"
        else
            error "Failed to apply patch: ${patch_file}"
        fi
    else
        error "Patch validation failed: ${patch_file}"
    fi
}

case "${1:-}" in
    "init") init_patch_system ;;
    "apply") shift; apply_patch "$1" ;;
    *) echo "Usage: $0 {init|apply <patch>}" ;;
esac
