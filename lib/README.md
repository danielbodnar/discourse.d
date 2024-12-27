# Library Directory

This directory contains core shell libraries and utility functions for the Discourse conversion project.

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


### 00-config.sh
Core configuration file containing environment variables and system settings.

#### Purpose
- Defines core paths and directories
- Sets user and group configurations
- Defines version requirements
- Configures resource limits

#### Key Variables
```bash
# Core paths
DISCOURSE_HOME="/home/discourse"
DISCOURSE_ROOT="/var/www/discourse"
DISCOURSE_DATA="/var/discourse"

# User/Group settings
DISCOURSE_USER="discourse"
DISCOURSE_GROUP="discourse"
DISCOURSE_UID="999"
DISCOURSE_GID="999"

# Version configurations
DISCOURSE_VERSION="3.2.1"
RUBY_VERSION="3.2.2"
NODE_VERSION="18.18.0"
```

#### See Also
- [SystemD Environment Variables](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#Environment%20variables%20in%20spawned%20processes)
- [Discourse Configuration](https://meta.discourse.org/t/configure-discourse-for-development/21089)

### 01-utils.sh
Utility functions for logging, validation, and common operations.

#### Purpose
- Provides consistent logging functions
- Implements validation helpers
- Offers common utility functions

#### Key Functions
```bash
log() { echo -e "${BLUE}[INFO]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
validate_environment() { ... }
```

### 02-structure.sh
Directory structure management and initialization.

#### Purpose
- Creates required directories
- Sets up permissions
- Manages volume mount points
- Initializes system structure

#### Key Functions
```bash
create_directory_structure() { ... }
setup_volume_links() { ... }
generate_volume_systemd_mount_units() { ... }
```



## Usage
Source these libraries in your scripts:
```bash
source /usr/lib/discourse/00-config.sh
source /usr/lib/discourse/01-utils.sh
source /usr/lib/discourse/02-structure.sh
```

