# Development Environment

## Prerequisites
- Docker
- Docker Compose
- Make (optional)

## Setup
1. Clone the repository:
```bash
git clone <repository-url>
cd discourse-conversion
```

2. Start the development environment:
```bash
./scripts/dev.sh start
```

3. Enter the development shell:
```bash
./scripts/dev.sh shell
```

## Usage

### Building Images
```bash
# Build all distributions
./scripts/dev.sh build

# Build specific distribution
./scripts/dev.sh build alpine
```

### Testing
```bash
# Run tests
./scripts/dev.sh test

# Test specific distribution
./scripts/dev.sh test alpine
```

### Development Shell
```bash
# Enter development container
./scripts/dev.sh shell
```

### Cleaning Up
```bash
# Remove build artifacts and containers
./scripts/dev.sh clean
```

## Environment Variables
- `DISCOURSE_VERSION`: Discourse version to build (default: 3.2.1)
- `RUBY_VERSION`: Ruby version to use (default: 3.2.2)
- `NODE_VERSION`: Node.js version to use (default: 18.18.0)
- `USER`: Development username (default: current user)
- `UID`: User ID (default: current UID)
- `GID`: Group ID (default: current GID)

## Volumes
- `.:/workspace`: Project directory
- `build-cache:/workspace/build`: Build cache
- `output-cache:/workspace/output`: Output cache

## Notes
- The development container runs with privileged mode to support systemd-nspawn
- Build artifacts are cached in Docker volumes for better performance
- The environment matches your host user to avoid permission issues
