# Building the BrightSign Monitoring Extension

This guide covers building the monitoring extension for both local testing and BrightSign player deployment.

## Prerequisites

### ⚠️ **IMPORTANT: squashfs-tools Required**

This extension **requires squashfs-tools** to build the compressed filesystem package. You must build on:
- **Linux machine** with squashfs-tools installed, OR
- **Linux container** (Docker/Podman) with squashfs-tools

**Windows and macOS users**: Use a Linux container or VM as described below.

### Platform-Specific Setup

#### Linux (Native Build Environment)
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y squashfs-tools curl tar make

# RHEL/CentOS/Fedora
sudo dnf install -y squashfs-tools curl tar make
# or
sudo yum install -y squashfs-tools curl tar make

# Verify installation
mksquashfs -version
```

#### macOS (Container Required)
macOS requires a Linux container since squashfs-tools don't work natively:

**Option 1: Docker**
```bash
# Install Docker Desktop for Mac
# Then run the build in a container:

docker run --rm -it -v $(pwd):/workspace ubuntu:22.04
# Inside container:
apt-get update && apt-get install -y squashfs-tools curl tar make
cd /workspace
make player-build
```

**Option 2: Lima/Colima**
```bash
# Install via Homebrew
brew install colima docker

# Start Linux VM
colima start

# Run build in container
docker run --rm -it -v $(pwd):/workspace ubuntu:22.04
# Inside container:
apt-get update && apt-get install -y squashfs-tools curl tar make  
cd /workspace
make player-build
```

#### Windows WSL (Recommended)
```bash
# Install Ubuntu WSL
wsl --install -d Ubuntu-22.04

# Inside WSL:
sudo apt-get update
sudo apt-get install -y squashfs-tools curl tar make

# Build the extension
make player-build
```

#### Container Build Script (All Platforms)
For convenience, use this one-liner to build in a container:

```bash
# Docker (works on macOS, Linux, Windows with Docker)
docker run --rm -v $(pwd):/workspace -w /workspace ubuntu:22.04 bash -c "
  apt-get update && 
  apt-get install -y squashfs-tools curl tar make && 
  make player-build
"
```

### System Requirements
- **Linux environment** (native, container, or WSL)
- **squashfs-tools** (mksquashfs command available)
- **Internet connection** for downloading ARM64 binaries
- **~1GB free disk space** for build artifacts

### Verify Prerequisites
```bash
# Check if squashfs-tools is available
which mksquashfs
mksquashfs -version

# Should output something like:
# mksquashfs version 4.5.1 (2022/03/15)
```

## Quick Start

### Build for BrightSign Player (Default)
```bash
# Build ARM64 extension for BrightSign players
make player-build

# Output: output/ext_mon-TIMESTAMP.zip
```

### Build for Local Testing
```bash
# Build for your local architecture
make test-build

# Test the build locally
make test-mount
make test-start
# Access: http://localhost:9090 (Prometheus), http://localhost:3000 (Grafana)
# Ports configurable via registry: mon-prometheus-port, mon-grafana-port
make test-stop
make test-unmount
```

## Build Modes

### 1. Player Build (`player-build`)
- **Target**: Linux ARM64 (BrightSign architecture)
- **Output**: Deployment package in `output/`
- **Purpose**: Production deployment to BrightSign players

```bash
make player-build
# Creates: output/ext_mon-TIMESTAMP.zip
```

### 2. Test Build (`test-build`)
- **Target**: Your local architecture (auto-detected)
- **Output**: Test directory in `install-test/`
- **Purpose**: Local testing before deployment

```bash
make test-build
# Creates: install-test/ directory for local testing
```

## Architecture Support

| Platform | Test Build | Player Build |
|----------|------------|--------------|
| Linux x86_64 | ✅ Full | ✅ Cross-compile |
| Linux ARM64 | ✅ Full | ✅ Native |
| macOS Intel | ✅ Full | ✅ Cross-compile |
| macOS Apple Silicon | ✅ Full | ✅ Cross-compile |
| Windows WSL | ✅ Full | ✅ Cross-compile |

## Build Process

### What the Build Does
1. **Downloads pre-built binaries**:
   - Prometheus 2.48.0
   - Grafana 10.2.3
2. **Configures services**:
   - Copies configuration files
   - Sets up provisioning (dashboards, datasources)
   - Configures init scripts
3. **Creates deployment package**:
   - SquashFS filesystem (compressed, read-only)
   - Installation script with hardcoded checksums
   - ZIP package for easy transfer

### Directory Structure
```
# During Build
build/              # Build artifacts
├── binaries/       # Downloaded binaries
install/            # Assembled extension
├── prometheus/     # Prometheus + configs
├── grafana/        # Grafana + configs
└── bsext_init      # Service control script

# Final Output
output/
├── ext_mon-TIMESTAMP.zip        # Deployment package
├── ext_mon.squashfs            # Extension filesystem
├── ext_mon_install-lvm.sh      # Installation script
└── README.md                   # Deployment instructions
```

## Available Make Targets

### Build Commands
```bash
make player-build    # Build for BrightSign (ARM64)
make test-build      # Build for local testing
make all             # Same as player-build
make help            # Show all available commands
```

### Component Commands
```bash
make download        # Download binaries only
make prometheus      # Download Prometheus only
make grafana         # Download Grafana only
make configure       # Set up configuration files
make package         # Create deployment package
make verify          # Verify binary architecture
```

### Testing Commands
```bash
make test-mount      # Mount test build locally
make test-start      # Start services locally
make test-stop       # Stop local services
make test-unmount    # Unmount test build
make test-status     # Check service status
make test-logs       # View service logs
```

### Maintenance Commands
```bash
make clean           # Remove build artifacts (current mode)
make clean-all       # Remove all build artifacts
make distclean       # Remove everything including downloads
make deps            # Install build dependencies
```

## Local Testing Workflow

After building for test:

```bash
# 1. Build for testing
make test-build

# 2. Mount the test build (simulates BrightSign mount)
make test-mount

# 3. Start services
make test-start

# 4. Access services
# - Prometheus: http://localhost:9090 (configurable via registry: mon-prometheus-port)
# - Grafana: http://localhost:3000 (admin/admin, configurable via registry: mon-grafana-port)

# 5. Check status
make test-status

# 6. View logs if needed
make test-logs

# 7. Stop and cleanup
make test-stop
make test-unmount
```

## Deployment to BrightSign

### 1. Build the Extension
```bash
make player-build
```

### 2. Transfer to Player
```bash
# Copy package to player
scp output/ext_mon-*.zip brightsign@player:/storage/sd/

# Or upload via Diagnostic Web Server (DWS)
```

### 3. Install on Player
```bash
# SSH to player
ssh brightsign@player

# Navigate and install
cd /storage/sd
unzip ext_mon-*.zip
bash ./ext_mon_install-lvm.sh

# Reboot to activate
reboot
```

### 4. Verify Installation
```bash
# After reboot, check services
ssh brightsign@player
/var/volatile/bsext/ext_mon/bsext_init status

# Access web interfaces
# - Prometheus: http://player:9090 (configurable via registry: mon-prometheus-port)
# - Grafana: http://player:3000 (admin/admin, configurable via registry: mon-grafana-port)
```

## Advanced Configuration

### Version Customization
Edit the Makefile to change versions:
```makefile
PROMETHEUS_VERSION := 2.48.0
GRAFANA_VERSION := 10.2.3
```

### Dashboard Configuration
The default dashboard is configured in two places:

**1. Grafana Configuration** (`configs/grafana/grafana.ini:166`):
```ini
[dashboards]
default_home_dashboard_uid = node-exporter-15172
```

**2. Dashboard File** (`configs/grafana/provisioning/dashboards/brightsign-node-exporter.json`):
- Contains the actual dashboard definition
- UID must match the `default_home_dashboard_uid` setting
- To use a different dashboard:
  1. Replace the JSON file with your custom dashboard
  2. Update the UID in `grafana.ini` to match your dashboard's UID
  3. Rebuild: `make rebuild`

### Registry Configuration (Runtime)
Configure services via BrightSign registry:
```bash
# Set custom ports
registry extension mon-prometheus-port 9091
registry extension mon-grafana-port 3001
registry extension mon-prometheus-node-exporter-port 9101

# Disable auto-start
registry extension mon-disable-auto-start false
```

### Development Workflow
```bash
# 1. Make configuration changes
vim configs/prometheus/prometheus.yml

# 2. Rebuild without re-downloading
make rebuild

# 3. Test locally first
make test-build && make test-mount && make test-start

# 4. Deploy to player
make player-build
scp output/ext_mon-*.zip player:/storage/sd/
```

## Troubleshooting

### Build Issues

**Missing squashfs-tools** (Most common issue):
```bash
# Error: "squashfs-tools not installed" or "mksquashfs: command not found"

# Linux: Install squashfs-tools
sudo apt-get install squashfs-tools  # Ubuntu/Debian
sudo dnf install squashfs-tools      # RHEL/CentOS/Fedora

# macOS/Windows: Use container
docker run --rm -v $(pwd):/workspace -w /workspace ubuntu:22.04 bash -c "
  apt-get update && apt-get install -y squashfs-tools curl tar make && 
  make player-build
"

# Verify installation
mksquashfs -version
```

**Wrong build environment**:
```bash
# Error: Building on macOS/Windows without container
# Solution: Use Docker container as shown above, or WSL on Windows

# WSL setup for Windows:
wsl --install -d Ubuntu-22.04
# Then install tools inside WSL and build there
```

**Download failures**:
```bash
# Check network connection
curl -I https://github.com/prometheus/prometheus/releases

# Manual download if needed - place in build/binaries/
```

**Architecture verification**:
```bash
# Verify ARM64 binaries were downloaded
make verify
```

**Container permission issues**:
```bash
# If output files have wrong ownership after container build
sudo chown -R $(whoami):$(whoami) output/
```

### Testing Issues

**Port conflicts**:
```bash
# Check if ports are in use
netstat -tln | grep -E "9090|3000"

# Stop conflicting services or use custom ports
```

**Permission denied**:
```bash
# Test mounting may require sudo
sudo make test-mount
# Or install bindfs: brew install bindfs
```

**Services won't start**:
```bash
# Check detailed logs
make test-logs

# Try manual start for debugging
cd /tmp/bsext/ext_mon
./prometheus/prometheus --help
```

### Player Deployment Issues

**Extension won't install**:
```bash
# Verify player is un-secured
# Check /storage/sd has enough space (need ~650MB)
df -h /storage/sd

# Check installation script logs
tail -f /var/log/messages
```

**Services not starting on player**:
```bash
# Check registry settings
/var/volatile/bsext/ext_mon/bsext_init status

# View service logs
tail -20 /var/log/prometheus.log
tail -20 /var/log/grafana.log
```

## Package Contents

The generated deployment package includes:
- ✅ Prometheus 2.48.0 (ARM64)
- ✅ Grafana 10.2.3 (ARM64) 
- ✅ Pre-configured dashboards (BrightSign Node Exporter)
- ✅ Service management scripts
- ✅ Auto-start on boot capability
- ✅ Registry-based configuration support

**Size**: ~200MB compressed, ~650MB installed

## Makefile Features

- **Auto-detection**: Detects your OS/architecture automatically
- **Colored output**: Visual progress indicators
- **Incremental builds**: Reuses downloads when possible
- **Parallel support**: Use `make -j4` for faster builds
- **Error handling**: Graceful fallbacks and clear error messages
- **Local overrides**: Create `Makefile.local` for custom settings

## Build Variables

View current configuration:
```bash
make vars
# Shows: versions, paths, URLs, architecture detection
```

Current defaults:
- **Prometheus Version**: 2.48.0
- **Grafana Version**: 10.2.3
- **Extension Name**: mon
- **Target Architecture**: ARM64 (player), Auto-detected (test)