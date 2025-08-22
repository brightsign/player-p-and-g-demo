# Makefile Usage Guide for BrightSign Monitoring Extension

## Quick Start

### 1. Build Everything (Recommended)
```bash
make all
```
This downloads ARM64 binaries, configures services, and creates the deployment package.

### 2. View Available Commands
```bash
make help
```

## Common Build Commands

### Full Build Process
```bash
# Complete build with package
make all

# Quick build without packaging (for testing)
make quick

# Rebuild package without re-downloading
make rebuild
```

### Individual Components
```bash
# Download Prometheus only
make prometheus

# Download Grafana only
make grafana

# Configure services
make configure

# Create package
make package

# Verify ARM64 binaries
make verify
```

### Maintenance
```bash
# Clean build artifacts (keeps downloads)
make clean

# Remove everything including downloads
make distclean

# Check build environment
make test

# Show build variables
make vars
```

## Build Output

After running `make all`, you'll find:

- **Package**: `output/ext_monitoring-TIMESTAMP.zip`
- **Installation Script**: 
  - `output/ext_monitoring_install-lvm.sh` (for LVM systems)
- **Documentation**: `output/README.md`

## Deployment Steps

1. **Build the extension**:
   ```bash
   make all
   ```

2. **Transfer to BrightSign player**:
   ```bash
   scp output/ext_monitoring-*.zip root@player:/storage/sd/
   ```

3. **Install on player**:
   ```bash
   ssh root@player
   cd /storage/sd
   unzip ext_monitoring-*.zip
   bash ./ext_monitoring_install-lvm.sh
   reboot
   ```

4. **Access monitoring**:
   - Prometheus: http://player:9090
   - Grafana: http://player:3000 (admin/admin)

## Advanced Usage

### Custom Versions
Edit the Makefile to change versions:
```makefile
PROMETHEUS_VERSION := 2.48.0
GRAFANA_VERSION := 10.2.3
```

### Development Workflow
```bash
# Make changes to configs
vim configs/prometheus/prometheus.yml

# Rebuild without downloading
make rebuild

# Test on player
scp output/ext_monitoring-*.zip root@player:/storage/sd/
```


### Install Build Dependencies
```bash
# Auto-install required tools
make deps
```

## Build Requirements

- **Required**: curl, tar
- **Optional**: mksquashfs (falls back to tar if not available)
- **Platform**: Linux/macOS/WSL

## Troubleshooting

### Missing squashfs-tools
The Makefile automatically falls back to tar format if mksquashfs is not available. To install:
```bash
# Debian/Ubuntu
sudo apt-get install squashfs-tools

# macOS
brew install squashfs

# Or use the Makefile
make deps
```

### Download Failures
If downloads fail, you can manually download ARM64 binaries:
- Prometheus: https://github.com/prometheus/prometheus/releases
- Grafana: https://grafana.com/grafana/download?platform=arm

Place tar.gz files in `build/binaries/` and run `make configure package`.

### Verification
Always verify ARM64 architecture:
```bash
make verify
```

## Makefile Features

- **Colored Output**: Visual feedback for build progress
- **Automatic Fallbacks**: Uses tar if squashfs unavailable
- **Incremental Builds**: Reuses downloads when available
- **Parallel Support**: Use `make -j4` for faster builds
- **Local Overrides**: Create `Makefile.local` for custom settings

## Example: Complete Build and Deploy

```bash
# Clean everything
make distclean

# Build extension
make all

# Verify ARM64 binaries
make verify

# Show package info
ls -lh output/

# Deploy to player
scp output/ext_monitoring-*.zip root@192.168.1.100:/storage/sd/
ssh root@192.168.1.100
cd /storage/sd && unzip ext_monitoring-*.zip
bash ./ext_monitoring_install-lvm.sh
reboot
```

## Package Contents

The generated package includes:
- ✅ Prometheus 2.48.0 (ARM64)
- ✅ Grafana 10.2.3 (ARM64)
- ✅ Configuration files
- ✅ Init scripts
- ✅ Installation scripts
- ✅ Pre-built dashboards
- ✅ Auto-start on boot

Total size: ~187MB compressed, ~650MB installed