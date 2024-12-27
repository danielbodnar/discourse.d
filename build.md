# Build Script

Main build script for creating Discourse images across all distributions.

## Purpose
- Coordinates the build process
- Manages distribution-specific builds
- Handles testing and validation
- Creates final images

## Usage
```bash
# Build all distributions
./build.sh build

# Build specific distribution
./build.sh build alpine

# Test builds
./build.sh test alpine
```

## Functions
```bash
build_rootfs() {
    # Builds root filesystem for specific distribution
}

build_all() {
    # Builds all supported distributions
}

test_build() {
    # Tests built images
}
```

## Environment Variables
```bash
BUILD_DIR="${SCRIPT_DIR}/build"
OUTPUT_DIR="${SCRIPT_DIR}/output"
```

## Test Integration
```bash
systemd-nspawn --image="${image}" \
    --bind="${SCRIPT_DIR}/test:/test" \
    /test/basic-test.sh
```

## See Also
- [mkosi Documentation](https://github.com/systemd/mkosi)
- [SystemD Container Interface](https://systemd.io/CONTAINER_INTERFACE/)