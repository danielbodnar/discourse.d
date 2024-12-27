
# Library Directory

Core library files for the Discourse container migration project.

## Files

### Configuration and Utilities
- `00-config.sh`: Core configuration variables
- `01-utils.sh`: Utility functions
- `02-structure.sh`: Directory structure management

### Build Components
- `ruby.sh`: Ruby environment setup
- `node.sh`: Node.js environment setup
- `bundler.sh`: Bundler configuration
- `yarn.sh`: Yarn package management
- `pnpm.sh`: PNPM package management

### Installation Scripts
- `setup-ruby.sh`: Ruby installation
- `setup-node.sh`: Node.js installation
- `install-plugins.sh`: Plugin management
- `pull-images.sh`: Container image management

### Integration
- `bitnami.sh`: Bitnami compatibility layer

## Usage
Files are sourced in numerical order by the main convert.sh script.
