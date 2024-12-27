
# Configuration Directory

Contains all configuration files for different environments and dependencies.

## Structure
```
config/
├── deps/           # Dependency configurations
│   ├── alpine.yaml # Alpine-specific packages
│   ├── arch.yaml   # Arch Linux packages
│   ├── debian.yaml # Debian packages
│   ├── fedora.yaml # Fedora packages
│   ├── gems.yaml   # Ruby gems
│   └── npm.yaml    # Node.js packages
├── ci.env         # CI environment variables
├── dev.env        # Development configuration
├── local.env      # Local development settings
├── prod.env       # Production configuration
└── qa.env         # QA environment settings
```

## Environment Files
Each .env file contains environment-specific configurations following SystemD conventions.
Environment files are loaded in order:
1. Base configuration
2. Environment specific (dev/qa/prod)
3. Local overrides

See [SystemD Environment Files](https://www.freedesktop.org/software/systemd/man/systemd.exec.html#EnvironmentFile=) for details.
