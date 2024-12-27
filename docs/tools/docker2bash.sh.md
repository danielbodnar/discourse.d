# Docker to Bash Converter Documentation

## Overview
The Docker to Bash Converter (docker2bash) is a tool that converts Dockerfile instructions into modular bash scripts. It decouples container build logic from Docker, allowing for more flexible and maintainable build processes.

## Features
- Converts Dockerfile commands to standalone bash scripts
- Creates modular build system
- Supports multi-stage builds
- Handles environment variables
- Manages file operations
- Provides user/group management
- Implements volume handling
- Supports entrypoint/cmd conversion

## Installation
```bash
curl -o docker2bash https://raw.githubusercontent.com/your-repo/docker2bash.sh
chmod +x docker2bash
sudo mv docker2bash /usr/local/bin/
```

## Usage
```bash
docker2bash --dockerfile ./Dockerfile --outdir ./build
```

### Arguments
- `--dockerfile`: Path to source Dockerfile
- `--outdir`: Output directory for generated scripts

## Output Structure
```plaintext
build/
├── bin/
│   └── entrypoint.sh
├── lib/
│   └── common.sh
├── scripts/
│   ├── 001-env.sh
│   ├── 002-run.sh
│   └── ...
├── build.sh
└── run.sh
```

## Script Components

### 1. Common Library (lib/common.sh)
```bash
# Common functions used across build scripts
log() { echo "[$(date)] $*"; }
error() { log "ERROR: $*"; exit 1; }
ensure_dir() { mkdir -p "$1"; }
```

### 2. Build Script (build.sh)
```bash
#!/bin/bash
# Main build orchestrator
set -euo pipefail

for script in scripts/*.sh; do
    if [ -x "$script" ]; then
        ./"$script"
    fi
done
```

### 3. Generated Scripts
Each Dockerfile instruction generates a corresponding bash script:

#### ENV Command
```bash
# scripts/001-env.sh
export RUBY_VERSION=3.2.2
export NODE_VERSION=18.18.0
```

#### RUN Command
```bash
# scripts/002-run.sh
apt-get update
apt-get install -y ruby nodejs
```

## Multi-stage Build Support

### Stage Management
```bash
# Stage definition
stage "builder" {
    FROM alpine:3.19
    RUN apk add build-base
}

# Stage artifact copying
copy_from "builder" "/build/app" "/usr/local/bin/app"
```

## Configuration

### Environment Variables
- `DOCKER2BASH_DEBUG`: Enable debug output
- `DOCKER2BASH_STRICT`: Enable strict mode
- `DOCKER2BASH_WORKDIR`: Set working directory

### Exit Codes
- 0: Success
- 1: Invalid arguments
- 2: Dockerfile parsing error
- 3: Script generation error

## Advanced Usage

### Custom Templates
```bash
docker2bash \
    --dockerfile ./Dockerfile \
    --outdir ./build \
    --template ./custom-template.sh
```

### Multi-stage Processing
```bash
docker2bash \
    --dockerfile ./Dockerfile \
    --outdir ./build \
    --stage-dir ./stages
```

## Best Practices

### 1. Script Organization
```plaintext
build/
├── stages/
│   ├── builder/
│   └── final/
├── lib/
└── scripts/
```

### 2. Error Handling
```bash
trap 'error "Build failed"' ERR
set -euo pipefail
```

### 3. Logging
```bash
log "Starting build phase: $phase"
```

## Integration Examples

### CI/CD Pipeline
```yaml
name: Build
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Convert Dockerfile
        run: docker2bash --dockerfile Dockerfile --outdir build
      - name: Run build
        run: cd build && ./build.sh
```

### Development Workflow
```bash
#!/bin/bash
# dev-build.sh

# Convert Dockerfile
docker2bash --dockerfile Dockerfile --outdir build

# Run build with development options
DOCKER2BASH_DEBUG=1 ./build/build.sh

# Run tests
./build/bin/run-tests.sh
```

## Troubleshooting

### Common Issues

1. Permission Errors
```bash
chmod -R +x build/scripts/
```

2. Missing Dependencies
```bash
# Install required tools
apt-get install jq gettext-base
```

3. Script Execution Order
```bash
# Force specific order
mv scripts/001-run.sh scripts/002-run.sh
```

## API Reference

### Functions

#### `parse_dockerfile()`
Parses Dockerfile and creates script structure.
```bash
parse_dockerfile "Dockerfile" "output_dir"
```

#### `create_script()`
Creates individual build script.
```bash
create_script "command" "args" "output_file"
```

## Contributing

### Development Setup
1. Clone repository
2. Install dependencies
3. Run tests
```bash
./tests/run-all.sh
```

### Testing
```bash
# Run unit tests
./tests/unit/run.sh

# Run integration tests
./tests/integration/run.sh
```
