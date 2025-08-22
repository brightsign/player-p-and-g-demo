# BrightSign Mon Extension - Installation Troubleshooting

When the monitoring extension isn't running on the actual BrightSign player after installation, follow these troubleshooting steps in order.

## 1. Verify Extension Installation

Check if the extension is properly mounted and accessible:

```bash
# Check if extension is mounted
df -h | grep ext_mon
mount | grep ext_mon

# Check extension directory exists  
ls -la /var/volatile/bsext/ext_mon/
```

**Expected Result**: The extension should be mounted at `/var/volatile/bsext/ext_mon/` and contain the Prometheus and Grafana directories.

## 2. Check Extension Service Status

Verify if the monitoring services are running:

```bash
# Check if services are running
ps | grep -E "prometheus|grafana"

# Check init script permissions and existence
ls -la /var/volatile/bsext/ext_mon/bsext_init
```

**Expected Result**: You should see both `prometheus` and `grafana-server` processes running, and the init script should be executable (`-rwxr-xr-x`).

## 3. Manual Service Testing

Test the extension's init script directly:

```bash
# Navigate to extension directory
cd /var/volatile/bsext/ext_mon

# Check service status
./bsext_init status

# Try starting services manually
./bsext_init start

# Check status again
./bsext_init status
```

**Expected Result**: Services should start without errors and show as running.

## 4. Binary Architecture Verification

Ensure the binaries are compatible with the player's ARM64 architecture:

```bash
# Check binary architecture
file /var/volatile/bsext/ext_mon/prometheus/prometheus
file /var/volatile/bsext/ext_mon/grafana/bin/grafana-server

# Try running binaries directly to test compatibility
cd /var/volatile/bsext/ext_mon/prometheus
./prometheus --version

cd /var/volatile/bsext/ext_mon/grafana/bin
./grafana-server -v
```

**Expected Result**: 
- `file` command should show: `ELF 64-bit LSB executable, ARM aarch64`
- Version commands should execute without "Exec format error"

## 5. Configuration File Verification

Check that all required configuration files are present:

```bash
# Check configuration files exist
ls -la /var/volatile/bsext/ext_mon/prometheus/prometheus.yml
ls -la /var/volatile/bsext/ext_mon/grafana/conf/grafana.ini

# Verify data directories are created
ls -la /var/volatile/bsext/ext_mon/prometheus/data/
ls -la /var/volatile/bsext/ext_mon/grafana/data/

# Check configuration file contents
head -10 /var/volatile/bsext/ext_mon/prometheus/prometheus.yml
head -10 /var/volatile/bsext/ext_mon/grafana/conf/grafana.ini
```

**Expected Result**: Configuration files should exist and contain valid YAML/INI syntax.

## 6. Port Conflicts and Network Issues

Check for port conflicts and network accessibility:

```bash
# Check if ports are already in use
netstat -tln | grep -E "9090|3000"

# Check for firewall restrictions
iptables -L | grep -E "9090|3000"

# Test port accessibility
curl -I http://localhost:9090 || echo "Prometheus port not responding"
curl -I http://localhost:3000 || echo "Grafana port not responding"
```

**Expected Result**: Ports 9090 and 3000 should be listening and accessible.

## 7. System Logs and Registry Settings

Check system logs and extension registry settings:

```bash
# Check system logs for errors
tail -20 /var/log/messages | grep -E "monitoring|prometheus|grafana"

# Check if auto-start is disabled via registry
registry extension monitoring-disable-auto-start

# Check general extension status
registry extension
```

**Expected Result**: No error messages in logs, and auto-start should not be disabled.

## 8. Manual Service Start (Debug Mode)

Start services manually with debug output to identify specific issues:

```bash
# Stop any running services first
cd /var/volatile/bsext/ext_mon
./bsext_init stop

# Start Prometheus manually with debug logging
cd prometheus
./prometheus --config.file=prometheus.yml --log.level=debug --storage.tsdb.path=./data --web.listen-address=:9090

# In a separate terminal, start Grafana manually
cd /var/volatile/bsext/ext_mon/grafana
export GF_PATHS_CONFIG=./conf/grafana.ini
export GF_PATHS_DATA=./data
export GF_PATHS_HOME=/var/volatile/bsext/ext_mon/grafana
./bin/grafana-server --config=./conf/grafana.ini
```

**Expected Result**: Services should start without errors and display startup logs.

## 9. Common Issues and Solutions

### Issue: "Exec format error"
- **Cause**: Binary architecture mismatch (trying to run AMD64 binaries on ARM64)
- **Solution**: Rebuild extension using `make playerbuild` to ensure ARM64 binaries

### Issue: "Permission denied" 
- **Cause**: Binaries are not executable
- **Solution**: 
  ```bash
  chmod +x /var/volatile/bsext/ext_mon/prometheus/prometheus
  chmod +x /var/volatile/bsext/ext_mon/grafana/bin/grafana-server
  chmod +x /var/volatile/bsext/ext_mon/bsext_init
  ```

### Issue: "Config file not found"
- **Cause**: Missing or incorrectly located configuration files
- **Solution**: Check file paths in bsext_init script and verify config files exist

### Issue: "Address already in use"
- **Cause**: Another service is using ports 9090 or 3000
- **Solution**: Stop conflicting services or modify port configuration

### Issue: Services start but aren't accessible
- **Cause**: Services binding to wrong interface
- **Solution**: Check if services are binding to localhost vs 0.0.0.0

## 10. Extension Reinstallation

If all else fails, completely reinstall the extension:

```bash
# Stop services
cd /var/volatile/bsext/ext_mon
./bsext_init stop

# Unmount and remove extension
cd /
umount /var/volatile/bsext/ext_mon 2>/dev/null || true
rm -rf /var/volatile/bsext/ext_mon

# Re-run installation script
cd /storage/sd  # or wherever your installation files are
bash ./ext_mon_install-lvm.sh

# Reboot player
reboot
```

## 11. Diagnostic Information Collection

If you need to report the issue, collect this diagnostic information:

```bash
# System information
uname -a
cat /proc/version

# Extension mount information
mount | grep ext_mon
df -h | grep ext_mon

# Process information
ps aux | grep -E "prometheus|grafana"

# Network information  
netstat -tln | grep -E "9090|3000"

# File permissions
ls -la /var/volatile/bsext/ext_mon/
ls -la /var/volatile/bsext/ext_mon/prometheus/prometheus
ls -la /var/volatile/bsext/ext_mon/grafana/bin/grafana-server

# Log files
tail -50 /var/log/messages | grep -E "monitoring|prometheus|grafana"
```

## Quick Reference Commands

```bash
# Check everything at once
cd /var/volatile/bsext/ext_mon && \
./bsext_init status && \
file prometheus/prometheus && \
file grafana/bin/grafana-server && \
netstat -tln | grep -E "9090|3000" && \
ps | grep -E "prometheus|grafana"
```

## Getting Help

If these steps don't resolve the issue:

1. Collect the diagnostic information from section 11
2. Note which specific step failed
3. Check the BrightSign developer documentation
4. Contact BrightSign support with the collected information

Most issues are caused by binary architecture mismatches or missing file permissions. Start with steps 2-4 to quickly identify the most common problems.