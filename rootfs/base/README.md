# Base Root Filesystem

Contains the common base filesystem shared across all distributions.

## Directory Structure
```bash
base/
├── etc/
│   ├── discourse/
│   │   ├── discourse.conf
│   │   └── discourse.conf.d/
│   ├── systemd/
│   │   └── system/
│   └── nginx/
├── usr/
│   ├── bin/
│   ├── lib/
│   │   └── discourse/
│   └── share/
└── var/
    ├── discourse/
    ├── log/
    └── run/
```

## Key Directories

### /etc/discourse/
Contains Discourse configuration files.

#### Files
- `discourse.conf`: Base configuration file
- `discourse.conf.d/*.conf`: Configuration overrides
  - `10-*.conf`: Distribution overrides
  - `50-*.conf`: Main configuration
  - `80-*.conf`: Environment overrides
  - `90-*.conf`: Local overrides

### /usr/lib/discourse/
Contains Discourse-specific scripts and utilities.

#### Files
- `discourse-env`: Environment setup
- `discourse-init`: Initialization script
- `backup-manager`: Backup management
- `install-ruby`: Ruby installation script

### /var/discourse/
Contains variable data directories.

#### Subdirectories
- `shared/`: Shared data
- `uploads/`: User uploads
- `backups/`: Backup files
- `public/assets/`: Compiled assets
- `plugins/`: Discourse plugins

## Configuration Examples

### discourse.conf
```bash
# Core Settings
DISCOURSE_HOSTNAME="localhost"
DISCOURSE_DEVELOPER_EMAILS="admin@localhost"

# Database Configuration
POSTGRES_HOST="localhost"
POSTGRES_PORT="5432"

# Redis Configuration
REDIS_HOST="localhost"
REDIS_PORT="6379"
```

### SystemD Service
```ini
[Unit]
Description=Discourse Discussion Platform
After=network.target postgresql.service redis.service

[Service]
Type=notify
User=discourse
Group=discourse
ExecStart=/usr/bin/discourse-server
```

## See Also
- [Discourse Configuration](https://meta.discourse.org/t/configure-discourse-for-development/21089)
- [SystemD Documentation](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
