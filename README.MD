# BrightSign Mon Extension

A self-contained Prometheus and Grafana monitoring extension for BrightSign digital signage players. Enables local metrics collection and visualization without external infrastructure.

## Quick Start

### Prerequisites
**⚠️ Requires Linux environment with squashfs-tools:**
- **Linux**: Install `squashfs-tools` package  
- **macOS/Windows**: Use Docker container or WSL

See [BUILD.md](docs/BUILD.md) for detailed setup instructions.

### Build and Deploy
```bash
# Build the extension (requires Linux + squashfs-tools)
make player-build

# Transfer to player
scp output/ext_mon-*.zip brightsign@player:/storage/sd/

# Install on player
ssh brightsign@player 'cd /storage/sd && unzip ext_mon-*.zip && bash ext_mon_install-lvm.sh && reboot'
```

### Access Monitoring
- **Prometheus**: http://player:9090
- **Grafana**: http://player:3000 (admin/admin)

## What's Included

- **Prometheus 2.48.0** (ARM64) - Metrics collection and storage
- **Grafana 10.2.3** (ARM64) - Dashboard and visualization
- **Pre-configured dashboards** - BrightSign-optimized Node Exporter dashboard (default) plus system monitoring
- **Automatic service management** - Starts on boot, survives reboots
- **Registry-based configuration** - Customize ports and behavior via BrightSign registry

## Configuration

The extension supports runtime configuration via BrightSign registry keys:

### Registry Configuration Options

| Registry Key | Default | Description |
|--------------|---------|-------------|
| `mon-disable-auto-start` | `true` | Set to `false` to prevent auto-start on boot |
| `mon-prometheus-port` | `9090` | Port for Prometheus web interface |
| `mon-grafana-port` | `3000` | Port for Grafana web interface |
| `mon-prometheus-node-exporter-port` | `9100` | Port where Node Exporter is running |

### Configuration Examples

```bash
# Disable auto-start (services won't start on boot)
registry extension mon-disable-auto-start false

# Use custom ports to avoid conflicts
registry extension mon-prometheus-port 9091
registry extension mon-grafana-port 3001
registry extension mon-prometheus-node-exporter-port 9101

# Reset to defaults (remove registry keys)
registry extension mon-disable-auto-start
registry extension mon-prometheus-port
registry extension mon-grafana-port
registry extension mon-prometheus-node-exporter-port

# View current configuration and service status
/var/volatile/bsext/ext_mon/bsext_init status
```

**Note**: Configuration changes require restarting services to take effect:
```bash
/var/volatile/bsext/ext_mon/bsext_init restart
```

## Service Management

### Manual Control
```bash
# Check service status
/var/volatile/bsext/ext_mon/bsext_init status

# Start services
/var/volatile/bsext/ext_mon/bsext_init start

# Stop services  
/var/volatile/bsext/ext_mon/bsext_init stop

# Restart services (apply configuration changes)
/var/volatile/bsext/ext_mon/bsext_init restart

# Run in foreground (debugging)
/var/volatile/bsext/ext_mon/bsext_init run
```

### Service Information
- **Auto-start**: Services start automatically on boot (unless disabled via registry)
- **Data storage**: Prometheus data in `/tmp/prometheus_data`, Grafana data in `/tmp/grafana_data`
- **Logs**: Written to `/var/log/` (or `/tmp/` if not writable)
  - Prometheus: `/var/log/prometheus.log`
  - Grafana: `/var/log/grafana.log`

## Supported Hardware

- **BrightSign Series 4 and 5** players (ARM64 architecture)
- **BrightSign OS 9.x** or later
- **Minimum 4GB** free storage space
- **Network connectivity** for accessing web interfaces

## Performance Impact

- **CPU**: ~5-10% during normal operation  
- **Memory**: ~150-200MB combined
- **Storage**: ~650MB installed
- **Network**: Local only (no external traffic)

## Default Dashboard

The extension includes a BrightSign-optimized Node Exporter dashboard with **10 monitoring panels** in a 3x3+1 grid layout:

**Row 1 (Top):**
- **CPU Core Use** - Per-core CPU utilization percentages
- **System Load** - 1m, 5m, 15m load averages  
- **Uptime (minutes)** - System uptime tracking

**Row 2 (Middle):**
- **Memory Usage** - System memory utilization percentage (0-100%)
- **Temperatures** - All thermal zones (SoC, Big/Little CPU cores, GPU, NPU) with 25-45°C range
- **% SD Card Used** - BrightSign-specific SD card usage percentage

**Row 3 (Bottom):**
- **Memory Details** - Detailed memory breakdown (Total, Available, Cached, Buffers)
- **Network I/O (eth0)** - Ethernet receive/transmit rates
- **Disk I/O (eMMC & SD)** - Read/write metrics for both storage devices

All panels display data as **time-series graphs** for trend analysis with optimized scaling and color-coded thresholds.

## Troubleshooting

### Service Issues
```bash
# Check if services are running
/var/volatile/bsext/ext_mon/bsext_init status

# View recent logs
tail -20 /var/log/prometheus.log
tail -20 /var/log/grafana.log

# Check registry configuration
registry extension mon-disable-auto-start
registry extension mon-prometheus-port
registry extension mon-grafana-port
```

### Web Interface Issues
- **Cannot access interfaces**: Check if services are running and ports are not blocked
- **Data not showing**: Verify Node Exporter is running on the configured port (default 9100)
- **Dashboard issues**: Check Grafana logs for provisioning errors

### Common Solutions
```bash
# Restart services to apply configuration changes
/var/volatile/bsext/ext_mon/bsext_init restart

# Reset to default ports
registry extension mon-prometheus-port
registry extension mon-grafana-port
registry extension mon-prometheus-node-exporter-port

# Enable auto-start if disabled
registry extension mon-disable-auto-start
```

See [installation-troubleshooting.md](docs/installation-troubleshooting.md) for detailed troubleshooting steps.

## Removal

To remove the extension:

```bash
# Connect to player and stop services
ssh brightsign@player
/var/volatile/bsext/ext_mon/bsext_init stop

# Verify services stopped
ps | grep -E "prometheus|grafana"

# Run uninstall script
/var/volatile/bsext/ext_mon/uninstall.sh

# Reboot to complete removal
reboot
```

Alternatively, perform a Factory Reset on the player to remove all extensions.

## Build Instructions

For building the extension, testing locally, or modifying configurations:

- **[BUILD.md](docs/BUILD.md)** - Complete build instructions, testing, and deployment
- **[installation-troubleshooting.md](docs/installation-troubleshooting.md)** - Detailed troubleshooting guide

## Package Information

- **Build Date**: Generated at build time
- **Prometheus**: 2.48.0 (ARM64)
- **Grafana**: 10.2.3 (ARM64) 
- **Package Size**: ~200MB compressed, ~650MB installed
- **License**: Apache 2.0 License

This extension incorporates:
- Prometheus (Apache License 2.0)
- Grafana (AGPL v3.0)