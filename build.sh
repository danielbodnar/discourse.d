
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# Source our configuration
source "${SCRIPT_DIR}/lib/00-config.sh"
source "${SCRIPT_DIR}/lib/01-utils.sh"

build_rootfs() {
    local dist="$1"
    log "Building rootfs for ${dist}..."
    
    # Generate distribution-specific mkosi config
    sed "s/@DISTRIBUTION@/${dist}/" mkosi.defaults.conf > "mkosi.${dist}.build.conf"
    
    # Build the base image
    mkosi -f "mkosi.${dist}.build.conf" build
    
    success "Built rootfs for ${dist}"
}

build_all() {
    mkdir -p "${BUILD_DIR}" "${OUTPUT_DIR}"
    
    for dist in "${DISTRIBUTIONS[@]}"; do
        build_rootfs "$dist"
    done
}

test_build() {
    local dist="$1"
    local image="${OUTPUT_DIR}/discourse-${dist}.raw"
    
    log "Testing ${dist} build..."
    
    systemd-nspawn --image="${image}" \
        --bind="${SCRIPT_DIR}/test:/test" \
        /test/basic-test.sh
}

main() {
    case "${1:-build}" in
        "build")
            build_all
            ;;
        "test")
            shift
            test_build "${1:-alpine}"
            ;;
        *)
            echo "Usage: $0 {build|test [distribution]}"
            exit 1
            ;;
    esac
}

main "$@"
