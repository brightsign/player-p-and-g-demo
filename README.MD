# BrightSign Mon Extension

A self-contained Prometheus and Grafana monitoring extension for BrightSign digital signage players. Enables local metrics collection and visualization without external infrastructure.

## Quick Start

```bash
# Build the extension
make playerbuild

# Deploy to BrightSign player
scp output/ext_mon-*.zip brightsign@player:/storage/sd/
ssh brightsign@player 'cd /storage/sd && unzip ext_mon-*.zip && bash ext_mon_install-lvm.sh && reboot'

# Access monitoring interfaces
# Prometheus: http://player:9090
# Grafana: http://player:3000 (admin/admin)
```

## What's Included

- **Prometheus 2.48.0** (ARM64) - Metrics collection and storage
- **Grafana 10.2.3** (ARM64) - Dashboard and visualization
- **Pre-configured dashboards** - BrightSign system metrics
- **Automatic service management** - Starts on boot, survives reboots

## Supported Hardware

- BrightSign Series 4 and 5 players (ARM64 architecture)
- Requires BrightSign OS 9.x or later
- Minimum 4GB free storage space

## Documentation

| Topic | Link |
|-------|------|
| **Installation & Troubleshooting** | [docs/installation-troubleshooting.md](docs/installation-troubleshooting.md) |
| **Build Instructions** | [docs/BUILD_INSTRUCTIONS.md](docs/BUILD_INSTRUCTIONS.md) |
| **Build Modes (Test vs Player)** | [docs/BUILD_MODES.md](docs/BUILD_MODES.md) |
| **Makefile Usage** | [docs/MAKEFILE_USAGE.md](docs/MAKEFILE_USAGE.md) |
| **Implementation Plan** | [docs/plan.md](docs/plan.md) |
| **Download Scripts** | [docs/build-scripts/](docs/build-scripts/) |

## Build System

```bash
# Player build (ARM64 for BrightSign)
make playerbuild

# Test build (local architecture)
make testbuild

# View all options
make help
```

## Repository Structure

```
├── Makefile                 # Build automation
├── configs/                 # Service configurations
│   ├── prometheus/          # Prometheus config
│   └── grafana/            # Grafana config & dashboards
├── sh/                     # Build and service scripts
├── docs/                   # Documentation
└── output/                 # Generated packages
```

## Performance Impact

- CPU: ~5-10% during normal operation  
- Memory: ~150-200MB combined
- Storage: ~650MB installed
- Network: Local only (no external traffic)

## License

Apache 2.0 License

This extension incorporates:
- Prometheus (Apache License 2.0)
- Grafana (AGPL v3.0)