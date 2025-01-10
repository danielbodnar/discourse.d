# Container and Rootfs Diffing/Rebasing Guide

## Direct Comparison Tools

### container-diff (Google)
```bash
# Install
curl -LO https://storage.googleapis.com/container-diff/latest/container-diff-linux-amd64
chmod +x container-diff-linux-amd64
sudo mv container-diff-linux-amd64 /usr/local/bin/container-diff

# Compare two containers
container-diff diff daemon://image1 daemon://image2 \
    --type=file \
    --type=size \
    --type=history \
    --type=metadata

# Compare specific aspects
container-diff diff alpine:3.16 alpine:3.17 \
    --type=apt \
    --type=pip \
    --type=node \
    --json

# Compare with local rootfs
container-diff diff dir:///path/to/rootfs1 dir:///path/to/rootfs2 \
    --type=file \
    --type=size
```

### skopeo with umoci
```bash
#!/bin/bash
# diff_and_rebase.sh
set -euo pipefail

# Extract both images
mkdir -p {image1,image2}
skopeo copy docker://alpine:3.16 oci:image1:latest
skopeo copy docker://alpine:3.17 oci:image2:latest

# Use umoci to unpack
umoci unpack --image image1:latest bundle1
umoci unpack --image image2:latest bundle2

# Generate diff
diff -Naur bundle1/rootfs bundle2/rootfs > rootfs.patch

# Apply diff to new base
umoci unpack --image newbase:latest newbundle
patch -p1 -d newbundle/rootfs < rootfs.patch
umoci repack --image newimage:latest newbundle
```

### buildah
```bash
#!/bin/bash
# buildah_rebase.sh
set -euo pipefail

# Create containers from images
container1=$(buildah from alpine:3.16)
container2=$(buildah from alpine:3.17)

# Mount containers
mount1=$(buildah mount $container1)
mount2=$(buildah mount $container2)

# Generate diff
diff -Naur $mount1 $mount2 > changes.patch

# Rebase onto new image
new_container=$(buildah from ubuntu:latest)
new_mount=$(buildah mount $new_container)
patch -p1 -d $new_mount < changes.patch

# Commit changes
buildah commit $new_container rebased-image
```

## Advanced Diffing Tools

### dive
```bash
# Install
wget https://github.com/wagoodman/dive/releases/download/v0.9.2/dive_0.9.2_linux_amd64.deb
sudo dpkg -i dive_0.9.2_linux_amd64.deb

# Analyze image layers
dive alpine:latest

# Compare two images
dive alpine:3.16 --diff alpine:3.17
```

### container-inspector
```bash
#!/bin/bash
# inspect_layers.sh
set -euo pipefail

# Extract image layers
skopeo copy docker://image1 oci:layers1:latest
skopeo copy docker://image2 oci:layers2:latest

# Compare layer contents
for layer in layers1/blobs/sha256/*; do
    layer_id=$(basename $layer)
    if [ -f "layers2/blobs/sha256/$layer_id" ]; then
        echo "Layer $layer_id exists in both images"
        diff -r $layer "layers2/blobs/sha256/$layer_id"
    fi
done
```

## Rebasing Tools

### umoci
```bash
#!/bin/bash
# umoci_rebase.sh
set -euo pipefail

# Extract original image
umoci unpack --image original:latest original-bundle

# Extract new base
umoci unpack --image newbase:latest newbase-bundle

# Create layer diff
mkdir -p changes
rsync -av --compare-dest=newbase-bundle/rootfs/ \
    original-bundle/rootfs/ changes/

# Apply changes to new base
umoci unpack --image newbase:latest rebase-bundle
rsync -av changes/ rebase-bundle/rootfs/

# Create new image
umoci repack --image rebased:latest rebase-bundle
```

### buildkit
```bash
#!/bin/bash
# buildkit_rebase.sh
set -euo pipefail

# Create temporary Dockerfile for rebasing
cat > Dockerfile.rebase <<EOF
FROM newbase:latest
COPY --from=original:latest /changed/path /changed/path
EOF

# Use buildctl for rebasing
buildctl build \
    --frontend=dockerfile.v0 \
    --local context=. \
    --local dockerfile=. \
    --output type=image,name=rebased:latest
```

## Automated Rebasing

### crane
```bash
#!/bin/bash
# crane_rebase.sh
set -euo pipefail

# Pull images
crane pull original:latest original.tar
crane pull newbase:latest newbase.tar

# Extract and analyze
mkdir -p {original,newbase}
tar xf original.tar -C original
tar xf newbase.tar -C newbase

# Create rebase manifest
cat > manifest.json <<EOF
{
  "schemaVersion": 2,
  "baseImage": "newbase:latest",
  "changes": [
    {
      "path": "/app",
      "source": "original:/app"
    }
  ]
}
EOF

# Perform rebase
crane mutate --tag rebased:latest \
    --base newbase:latest \
    --apply manifest.json
```

## Composable Diffing and Rebasing

### Using overlay-diff
```bash
#!/bin/bash
# overlay_diff_rebase.sh
set -euo pipefail

# Set up overlay mounts for both images
mkdir -p {image1,image2}/{lower,upper,work,merged}

# Mount first image
container1=$(buildah from image1)
mount1=$(buildah mount $container1)
sudo mount -t overlay overlay \
    -o lowerdir=$mount1,upperdir=image1/upper,workdir=image1/work \
    image1/merged

# Mount second image
container2=$(buildah from image2)
mount2=$(buildah mount $container2)
sudo mount -t overlay overlay \
    -o lowerdir=$mount2,upperdir=image2/upper,workdir=image2/work \
    image2/merged

# Generate diff using overlayfs
sudo diff -Naur image1/merged image2/merged > changes.patch

# Apply to new base
new_container=$(buildah from newbase)
new_mount=$(buildah mount $new_container)
sudo mount -t overlay overlay \
    -o lowerdir=$new_mount,upperdir=newbase/upper,workdir=newbase/work \
    newbase/merged
patch -p1 -d newbase/merged < changes.patch
```

## Best Practices

### Layer Analysis
```bash
# Analyze layer efficiency
dive image:tag -j > analysis.json

# Find duplicate files across layers
jq -r '.Layer[] | select(.Duplicates != null) | .Duplicates[]' analysis.json

# Check layer size impact
container-diff analyze image:tag --type=size --json | \
    jq '.Analytics[].Results[] | select(.Size > 10485760)'
```

### Efficient Rebasing
```bash
#!/bin/bash
# efficient_rebase.sh
set -euo pipefail

# Extract only changed files
buildah mount $(buildah from image1) > mount1
buildah mount $(buildah from image2) > mount2
rsync -av --compare-dest=$mount1/ $mount2/ changes/

# Create minimal layer
cat > Dockerfile.minimal <<EOF
FROM newbase:latest
COPY changes /
EOF

# Build with minimal layer
buildah bud -t rebased:latest -f Dockerfile.minimal .
```

### Reproducible Builds
```bash
#!/bin/bash
# reproducible_rebase.sh
set -euo pipefail

# Create deterministic diff
diff -Naur --no-dereference \
    --exclude-from=exclude.txt \
    original/ modified/ > changes.patch

# Apply with timestamp preservation
patch -p1 --no-backup-if-mismatch \
    --forward --directory=newbase < changes.patch

# Verify reproducibility
sha256sum original/rootfs newbase/rootfs
```

## Advanced Use Cases

### Cross-Distribution Rebasing
```bash
#!/bin/bash
# cross_distro_rebase.sh
set -euo pipefail

# Extract application files from source
container=$(buildah from source:latest)
mount=$(buildah mount $container)
app_files=$(find $mount/app -type f)

# Create new base with dependencies
cat > Dockerfile.deps <<EOF
FROM newbase:latest
RUN apt-get update && apt-get install -y \
    $(cat dependencies.txt)
EOF

# Copy app files and configurations
buildah bud -t rebased:latest -f Dockerfile.deps .
new_container=$(buildah from rebased:latest)
new_mount=$(buildah mount $new_container)
rsync -av --files-from=<(echo "$app_files") $mount $new_mount
```

Would you like me to expand on any of these tools or provide more specific examples for certain scenarios?