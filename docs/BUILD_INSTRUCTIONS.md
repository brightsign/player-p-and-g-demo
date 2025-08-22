# Build Instructions for BrightSign Mon Extension

## Overview
This document provides step-by-step instructions for building the BrightSign mon extension with Prometheus and Grafana.

## Prerequisites

1. **BrightSign SDK** (if you already have it from the original project)
   - Located in `./sdk/` directory
   - If not available, follow original README to build SDK first

2. **Required tools**
   ```bash
   # Install on Ubuntu/Debian
   sudo apt-get update
   sudo apt-get install -y squashfs-tools git make cmake
   ```

## Build Process

### Step 1: Build Prometheus and Grafana Binaries

#### Manual Build

1. **Set up cross-compilation environment**
   ```bash
   source ./sdk/environment-setup-aarch64-oe-linux
   ```

2. **Build Prometheus**
   ```bash
   git clone https://github.com/prometheus/prometheus.git
   cd prometheus
   git checkout v2.48.0
   
   GOOS=linux GOARCH=arm64 CGO_ENABLED=0 make build
   
   # Copy to install directory
   cp prometheus ../install/prometheus/
   cp promtool ../install/prometheus/
   cd ..
   ```

3. **Build Grafana**
   ```bash
   git clone https://github.com/grafana/grafana.git
   cd grafana
   git checkout v10.2.0
   
   # Build frontend
   yarn install --immutable
   yarn build
   
   # Build backend
   GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go run build.go build
   
   # Copy to install directory
   cp bin/linux-arm64/grafana ../install/grafana/bin/grafana-server
   cp -r public/* ../install/grafana/public/
   cd ..
   ```

### Step 2: Prepare Extension Files

1. **Copy binaries to install directory**
   ```bash
   cp -r binaries/prometheus/* install/prometheus/
   cp -r binaries/grafana/* install/grafana/
   ```

2. **Ensure configuration files are in place**
   ```bash
   # Check configurations
   ls -la configs/prometheus/prometheus.yml
   ls -la configs/grafana/grafana.ini
   ls -la configs/grafana/provisioning/
   ```

3. **Set up install directory structure**
   ```bash
   # Run CMake to copy configs
   mkdir -p build
   cd build
   cmake ..
   make install
   cd ..
   ```

### Step 3: Package the Extension

1. **Create the extension package**
   ```bash
   # For LVM-based systems
   sh/pkg-dev.sh install lvm
   ```

2. **Verify the package**
   ```bash
   # Check for the generated files
   ls -la ext_monitoring-*.zip
   ls -la ext_monitoring_install-lvm.sh
   ls -la ext_monitoring.squashfs
   ```

## Deployment to BrightSign Player

### Prerequisites
- BrightSign player must be un-secured (development mode)
- SSH access configured
- Player connected to network

### Installation Steps

1. **Transfer package to player**
   - Use DWS (Diagnostic Web Server) to upload the zip file
   - Or use SCP: `scp ext_monitoring-*.zip root@<player-ip>:/storage/sd/`

2. **Install on player**
   ```bash
   # SSH to player
   ssh root@<player-ip>
   
   # Drop to Linux shell (Ctrl-C, exit, exit)
   
   # Extract and install
   cd /usr/local
   unzip /storage/sd/ext_monitoring-*.zip
   bash ./ext_monitoring_install-lvm.sh
   
   # Reboot to activate
   reboot
   ```

3. **Verify installation**
   ```bash
   # After reboot, SSH back to player
   ps | grep -E "prometheus|grafana"
   
   # Check services
   /var/volatile/bsext/ext_monitoring/bsext_init status
   ```

## Access Monitoring Interfaces

Once installed and running:

- **Prometheus**: http://<player-ip>:9090
- **Grafana**: http://<player-ip>:3000
  - Default login: admin/admin

## Troubleshooting

### Build Issues

1. **Cross-compilation errors**
   - Verify SDK is properly sourced
   - Check Go version (need 1.19+)
   - Ensure all environment variables are set

3. **Missing dependencies**
   ```bash
   # Install additional tools if needed
   sudo apt-get install -y golang nodejs yarn
   ```

### Deployment Issues

1. **Services not starting**
   ```bash
   # Check logs
   tail -f /var/log/messages | grep ext_monitoring
   
   # Try manual start
   /var/volatile/bsext/ext_monitoring/bsext_init run
   ```

2. **Cannot access web interfaces**
   - Check firewall settings
   - Verify services are running
   - Test with curl: `curl http://localhost:9090/metrics`

3. **High resource usage**
   - Modify scrape intervals in prometheus.yml
   - Reduce retention period
   - Disable unnecessary collectors

## Development Workflow

For iterative development:

1. **Make changes to configurations**
2. **Rebuild package**: `sh/pkg-dev.sh install lvm`
3. **Upload and test on player**
4. **Check logs and metrics**
5. **Iterate as needed**

## Clean Build

To start fresh:
```bash
# Remove build artifacts
rm -rf build/ install/prometheus/prometheus install/grafana/bin/
rm -f ext_monitoring-*.zip
rm -f ext_monitoring.squashfs ext_monitoring_install-lvm.sh

# Rebuild everything
sh/pkg-dev.sh install lvm
```

## Notes

- The extension will persist across player reboots
- Data is stored in `/var/volatile/bsext/ext_monitoring/*/data/`
- To uninstall, see the main README for removal instructions
- For production use, get the extension signed by BrightSign

## Support

For issues or questions:
- Check the main README.md
- Review plan.md for detailed implementation notes
- Contact BrightSign support for player-specific issues