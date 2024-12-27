# Test Directory

Contains test scripts and validation tools for the Discourse conversion project.

## Files

### basic-test.sh
Basic system validation script.

#### Purpose
- Validates system configuration
- Checks required services
- Verifies directory structure
- Tests permissions

#### Tests Performed
```bash
# System checks
systemctl --version
id discourse

# Directory checks
for dir in /var/www/discourse /home/discourse /var/discourse; do
    [ -d "$dir" ] || exit 1
done

# Configuration checks
[ -d "/etc/discourse/discourse.conf.d" ] || exit 1
```

### Integration Tests
Future test implementations will include:
- Service startup tests
- Configuration validation
- Network connectivity
- Volume management
- Backup functionality

## Usage
```bash
# Run basic tests
./test/basic-test.sh

# Run through build system
./build.sh test alpine
```

## See Also
- [Discourse Testing Guide](https://meta.discourse.org/t/discourse-testing-guide/96587)
- [SystemD Testing](https://www.freedesktop.org/software/systemd/man/systemd-analyze.html)