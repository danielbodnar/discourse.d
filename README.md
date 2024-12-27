
# Discourse Container Migration Project

## Overview
Tools and scripts for migrating Discourse from Docker containers to SystemD portable services.

## Directory Structure
- `config/`: Configuration files and environment variables
- `dev-guide/`: Development environment setup
- `docs/`: Project documentation
- `lib/`: Core library scripts
- `patches/`: Sequential system patches
- `rootfs/`: Root filesystem structure
- `scripts/`: Helper scripts
- `src/`: Source configurations
- `test/`: Test suite
- `tools/`: Utility tools

## Getting Started
1. Initialize patch system:
```bash
./tools/patch-manager.sh init
```

2. Apply patches:
```bash
./tools/patch-manager.sh apply-all
```

3. Build system:
```bash
./convert.sh
```

## Configuration
Environment-specific configuration files are in `config/`:
- `dev.env`: Development settings
- `prod.env`: Production settings
- `qa.env`: Testing settings

## Development
See `dev-guide/` for development setup instructions.

## Testing
Run tests with:
```bash
./test/run-tests.sh
```

## Documentation
Comprehensive documentation available in `docs/`.
