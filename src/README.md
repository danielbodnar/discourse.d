
# Source Directory

Contains the base system files and configurations.

## Structure
```
src/
└── base/
    └── etc/
        └── discourse/
            ├── discourse.conf.d/  # Configuration overrides
            │   ├── 10-dist.conf   # Distribution-specific
            │   ├── 50-main.conf   # Main configuration
            │   ├── 80-env.conf    # Environment overrides
            │   └── 90-local.conf  # Local settings
            └── discourse.conf     # Base configuration
```

## Configuration Hierarchy
Files are processed in lexicographical order:
1. `10-dist.conf`: Distribution-specific settings
2. `50-main.conf`: Core configuration
3. `80-env.conf`: Environment variables
4. `90-local.conf`: Local overrides

See [Configuration Management](../docs/configuration.md) for more details.
