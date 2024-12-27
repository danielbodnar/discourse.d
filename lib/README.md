
# Library Directory

Core shell scripts and utilities for the Discourse build system.

## Files

### Configuration and Utilities
- `00-config.sh`: Core variables and settings
- `01-utils.sh`: Common utility functions
- `02-structure.sh`: Directory structure management

### Package Management
- `bundler.sh`: Ruby bundler configuration
- `node.sh`: Node.js setup and configuration
- `pnpm.sh`: PNPM package management
- `ruby.sh`: Ruby environment setup
- `yarn.sh`: Yarn package management

### Build Tools
- `pull-images.sh`: Image pulling utilities
- `bitnami.sh`: Bitnami migration helpers

## Usage
All library files are sourced by the main build scripts in order.
They provide core functionality for the build and migration process.
