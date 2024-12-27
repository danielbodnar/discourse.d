# mkosi Default Configuration

Base configuration file for mkosi image building.

## Purpose
Provides common configuration options for all distribution builds.

## Configuration
```ini
[Distribution]
Distribution=@DISTRIBUTION@
Release=@RELEASE@

[Output]
Format=gpt_ext4
Bootable=no
OutputDirectory=output
WorkspaceDirectory=work
BuildDirectory=build

[Content]
MakeInitrd=no
RemoveFiles=/var/cache/apt /var/lib/apt/lists
Environment=
    LANG=C.UTF-8
    LC_ALL=C.UTF-8

[Validation]
CheckSum=yes
Sign=no

[Host]
QemuHeadless=yes
```

## Usage
This file is used as the base configuration for all distribution-specific builds.

### Building Images
```bash
# For specific distribution
mkosi -f mkosi.defaults.conf -f mkosi.alpine.conf build

# For all distributions
for dist in alpine arch debian ubuntu; do
    mkosi -f mkosi.defaults.conf -f mkosi.${dist}.conf build
done
```

## See Also
- [mkosi Documentation](https://github.com/systemd/mkosi/tree/main/docs)
- [mkosi Configuration Guide](https://github.com/systemd/mkosi/blob/main/docs/configuration.md)