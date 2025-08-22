# Build Modes for BrightSign Monitoring Extension

This extension now supports two distinct build modes:

## 1. Test Build (Local Testing)

Build and run the monitoring stack on your development machine for testing before deploying to a BrightSign player.

### Building for Test

```bash
make testbuild
```

This will:
- Detect your local architecture (x86_64, ARM64, etc.)
- Download appropriate binaries for your OS/architecture
- Create a test build in `install-test/` directory
- Prepare everything for local testing

### Testing Locally

After building, you can test the extension locally:

```bash
# 1. Mount the test build (simulates BrightSign mount)
make test-mount

# 2. Start the services
make test-start

# 3. Access the services
# Prometheus: http://localhost:9090
# Grafana: http://localhost:3000 (admin/admin)

# 4. Check service status
make test-status

# 5. View logs if needed
make test-logs

# 6. Stop services when done
make test-stop

# 7. Unmount the test build
make test-unmount
```

### Supported Test Platforms

- **Linux x86_64**: Full support
- **Linux ARM64**: Full support
- **macOS Intel**: Full support
- **macOS Apple Silicon**: Full support
- **Windows WSL**: Full support

## 2. Player Build (BrightSign Deployment)

Build the extension for deployment on BrightSign players (ARM64 architecture).

### Building for Player

```bash
make playerbuild
# or simply
make all
```

This will:
- Always build for Linux ARM64 (BrightSign architecture)
- Download ARM64 binaries
- Create deployment package in `output/` directory
- Generate installation scripts

### Deploying to Player

```bash
# 1. Transfer package to player
scp output/ext_monitoring-*.zip root@player-ip:/storage/sd/

# 2. Install on player
ssh root@player-ip
cd /storage/sd
unzip ext_monitoring-*.zip
bash ./ext_monitoring_install-lvm.sh
reboot

# 3. Access services
# Prometheus: http://player-ip:9090
# Grafana: http://player-ip:3000
```

## Directory Structure

### Test Build
```
install-test/           # Test build directory
├── prometheus/         # Prometheus for your architecture
├── grafana/           # Grafana for your architecture
└── bsext_init         # Init script

build-test/            # Test build artifacts
└── binaries/          # Downloaded binaries

output-test/           # Test output (if needed)
```

### Player Build
```
install/               # Player build directory
├── prometheus/        # Prometheus ARM64
├── grafana/          # Grafana ARM64
└── bsext_init        # Init script

build/                # Player build artifacts
└── binaries/         # Downloaded ARM64 binaries

output/               # Player deployment package
├── ext_monitoring.squashfs
├── ext_monitoring_install-lvm.sh
└── ext_monitoring-*.zip
```

## Cleaning Builds

```bash
# Clean current mode's build
make clean

# Clean all builds (test and player)
make clean-all

# Remove everything including downloads
make distclean
```

## Architecture Detection

The Makefile automatically detects your system:

```bash
# Show detected architecture
make help
```

This will display:
- HOST_ARCH: Your CPU architecture
- HOST_OS: Your operating system
- Target architecture for each build mode

## Tips

1. **Test First**: Always use `testbuild` to verify configuration before deploying to players
2. **Port Conflicts**: Ensure ports 9090 and 3000 are free before testing
3. **Permissions**: Test mounting may require sudo on some systems
4. **macOS Note**: Uses bindfs if available, otherwise copies files
5. **Clean State**: Run `make clean-all` between switching build modes

## Troubleshooting

### Test Build Issues

```bash
# Check if services are running
make test-status

# View service logs
make test-logs

# Force stop and cleanup
make test-stop
make test-unmount
make clean-all
```

### Player Build Issues

```bash
# Verify ARM64 binaries
make verify

# Check package contents
unzip -l output/ext_monitoring-*.zip
```

## Advanced Usage

```bash
# Force specific build mode
BUILD_MODE=test make download configure
BUILD_MODE=player make download configure

# Parallel builds
make -j4 testbuild
make -j4 playerbuild
```