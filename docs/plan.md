# BrightSign Mon Extension Implementation Plan
## Prometheus and Grafana Integration for BrightSign Players

### Executive Summary
This implementation plan outlines the development of a BrightSign extension that integrates Prometheus and Grafana monitoring tools directly on BrightSign digital signage players. This enables local metrics collection and visualization without requiring external infrastructure.

---

## Project Scope

### Primary Objectives
1. Build a self-contained mon extension for BrightSign players
2. Deploy Prometheus for metrics collection from the player's Node Exporter
3. Deploy Grafana for metrics visualization
4. Enable demonstration of player monitoring capabilities without external dependencies

### Key Deliverables
- Cross-compiled Prometheus binary for ARM64/BrightSign OS
- Cross-compiled Grafana binary for ARM64/BrightSign OS
- Configuration files for both services
- Extension packaging with proper lifecycle management
- Documentation and deployment instructions

---

## Implementation Phases

### Phase 1: Environment Preparation
**Timeline: 2-3 hours**

#### Prerequisites
- [ ] Install required build tools (Go 1.19+, Node.js 18+, yarn)
- [ ] Setup BrightSign SDK (as per README.md instructions)
- [ ] Prepare development player (un-secured, SSH enabled)

#### Environment Setup
1. **SDK Configuration**
   ```bash
   export project_root=$(pwd)
   source ./sdk/environment-setup-aarch64-oe-linux
   ```

2. **Build Environment**
   - [ ] Create build directories structure
   - [ ] Setup cross-compilation environment variables
   - [ ] Verify toolchain functionality

---

### Phase 2: Prometheus Binary Download and Configuration
**Timeline: 1-2 hours**

#### 2.1 Binary Download
1. **Download Pre-built Binary**
   ```bash
   PROMETHEUS_VERSION="2.48.0"
   wget https://github.com/prometheus/prometheus/releases/download/v${PROMETHEUS_VERSION}/prometheus-${PROMETHEUS_VERSION}.linux-arm64.tar.gz
   tar -xzf prometheus-${PROMETHEUS_VERSION}.linux-arm64.tar.gz
   ```

2. **Verify Binary**
   - [ ] Check binary architecture with `file`
   - [ ] Verify it's ARM64/AArch64
   - [ ] Test basic functionality with `--version`

#### 2.3 Configuration
1. **Create prometheus.yml**
   ```yaml
   global:
     scrape_interval: 15s
     evaluation_interval: 15s

   scrape_configs:
     - job_name: 'brightsign-node'
       static_configs:
         - targets: ['localhost:9100']
           labels:
             instance: 'local-player'
   ```

2. **Directory Structure**
   ```
   install/
   ├── prometheus/
   │   ├── prometheus (binary)
   │   ├── prometheus.yml
   │   └── data/ (for TSDB)
   ```

---

### Phase 3: Grafana Binary Download and Configuration
**Timeline: 1-2 hours**

#### 3.1 Binary Download
1. **Download Pre-built Binary**
   ```bash
   GRAFANA_VERSION="10.2.3"
   wget https://dl.grafana.com/oss/release/grafana-${GRAFANA_VERSION}.linux-arm64.tar.gz
   tar -xzf grafana-${GRAFANA_VERSION}.linux-arm64.tar.gz
   ```

2. **Verify Binary**
   - [ ] Check binary architecture with `file`
   - [ ] Verify it's ARM64/AArch64
   - [ ] Test basic functionality with `--version`

#### 3.3 Configuration
1. **Create grafana.ini**
   ```ini
   [server]
   protocol = http
   http_port = 3000
   domain = localhost

   [database]
   type = sqlite3
   path = /var/volatile/bsext/ext_mon/grafana/data/grafana.db

   [security]
   admin_user = admin
   admin_password = admin

   [auth.anonymous]
   enabled = true
   org_role = Viewer
   ```

2. **Provision Datasource**
   ```yaml
   # datasources.yml
   apiVersion: 1
   datasources:
     - name: Prometheus
       type: prometheus
       access: proxy
       url: http://localhost:9090
       isDefault: true
   ```

---

### Phase 4: Extension Integration
**Timeline: 2-3 hours**

#### 4.1 Init Script Development
1. **Modify bsext_init**
   ```bash
   #!/bin/sh
   ### BEGIN INIT INFO
   # Provides:          monitoring
   # Required-Start:    $network $remote_fs
   # Required-Stop:     $network $remote_fs
   # Default-Start:     2 3 4 5
   # Default-Stop:      0 1 6
   # Short-Description: Prometheus and Grafana Monitoring
   ### END INIT INFO

   EXTENSION_DIR="$(dirname $0)"
   PROMETHEUS_BIN="$EXTENSION_DIR/prometheus/prometheus"
   GRAFANA_BIN="$EXTENSION_DIR/grafana/bin/grafana-server"
   
   start_prometheus() {
       start-stop-daemon --start --background \
           --make-pidfile --pidfile /var/run/prometheus.pid \
           --chdir "$EXTENSION_DIR/prometheus" \
           --exec "$PROMETHEUS_BIN" -- \
           --config.file=prometheus.yml \
           --storage.tsdb.path=./data
   }
   
   start_grafana() {
       start-stop-daemon --start --background \
           --make-pidfile --pidfile /var/run/grafana.pid \
           --chdir "$EXTENSION_DIR/grafana" \
           --exec "$GRAFANA_BIN" -- \
           --config=grafana.ini \
           --homepath="$EXTENSION_DIR/grafana"
   }
   ```

#### 4.2 Directory Structure
```
install/
├── bsext_init
├── prometheus/
│   ├── prometheus
│   ├── prometheus.yml
│   └── data/
├── grafana/
│   ├── bin/
│   │   └── grafana-server
│   ├── conf/
│   │   ├── grafana.ini
│   │   └── provisioning/
│   ├── public/
│   └── data/
```

---

### Phase 5: Testing and Validation
**Timeline: 2 hours**

#### 5.1 Local Testing
1. **Component Testing**
   - [ ] Test Prometheus binary execution
   - [ ] Test Grafana binary execution
   - [ ] Verify configuration loading
   - [ ] Check port bindings

2. **Integration Testing**
   - [ ] Verify Prometheus scrapes Node Exporter
   - [ ] Verify Grafana connects to Prometheus
   - [ ] Test dashboard creation
   - [ ] Validate metrics collection

#### 5.2 Player Testing
1. **Deployment**
   ```bash
   sh/pkg-dev.sh install lvm
   # Transfer to player
   # Install extension
   bash ./ext_monitoring_install-lvm.sh
   reboot
   ```

2. **Validation**
   - [ ] Check processes with `ps | grep -E "prometheus|grafana"`
   - [ ] Access Prometheus UI at http://player-ip:9090
   - [ ] Access Grafana UI at http://player-ip:3000
   - [ ] Verify metrics in both interfaces

---

### Phase 6: Optimization and Hardening
**Timeline: 2 hours**

#### 6.1 Performance Optimization
1. **Resource Management**
   - [ ] Configure memory limits
   - [ ] Optimize retention policies
   - [ ] Minimize disk usage
   - [ ] Reduce CPU overhead

2. **Startup Optimization**
   - [ ] Implement delayed start if needed
   - [ ] Add health checks
   - [ ] Configure restart policies

#### 6.2 Security Hardening
1. **Access Control**
   - [ ] Change default credentials
   - [ ] Implement authentication if needed
   - [ ] Restrict network access
   - [ ] Use local-only binding where possible

---

### Phase 7: Documentation and Delivery
**Timeline: 1-2 hours**

#### 7.1 Documentation
1. **User Documentation**
   - [ ] Installation guide
   - [ ] Configuration options
   - [ ] Troubleshooting guide
   - [ ] Dashboard creation tutorial

2. **Developer Documentation**
   - [ ] Build instructions
   - [ ] Customization guide
   - [ ] API endpoints reference

#### 7.2 Packaging for Production
1. **Final Package**
   - [ ] Create squashfs archive
   - [ ] Generate installation scripts
   - [ ] Prepare for signing process

2. **Submission**
   - [ ] Contact Partner Engineer
   - [ ] Submit for BrightSign signing
   - [ ] Test signed extension

---

## Technical Considerations

### Memory and Storage
- **Prometheus TSDB**: ~100MB initial, grows with retention
- **Grafana Database**: ~50MB initial
- **Binary Sizes**: 
  - Prometheus: ~100MB
  - Grafana: ~150MB
- **Total Extension Size**: ~400-500MB

### Network Ports
- Prometheus: 9090 (configurable)
- Grafana: 3000 (configurable)
- Node Exporter: 9100 (player default)

### Dependencies
- No external library dependencies (statically linked)
- Requires BrightSign OS 9.x or later
- Requires Node Exporter enabled on player

---

## Risk Analysis

### Technical Risks
1. **Cross-compilation Issues**
   - Mitigation: Use consistent SDK environment
   - Fallback: Use pre-built ARM64 binaries if available

2. **Resource Constraints**
   - Mitigation: Implement aggressive retention policies
   - Fallback: Reduce metrics collection frequency

3. **Version Compatibility**
   - Mitigation: Test on multiple OS versions
   - Fallback: Build multiple versions if needed

### Operational Risks
1. **Performance Impact**
   - Mitigation: Profile and optimize resource usage
   - Fallback: Make monitoring opt-in via registry

2. **Storage Exhaustion**
   - Mitigation: Implement rotation and cleanup
   - Fallback: Use memory-only storage

---

## Success Metrics

### Functional Requirements
- [ ] Prometheus successfully collects metrics
- [ ] Grafana successfully displays metrics
- [ ] Extension survives player reboots
- [ ] Clean start/stop functionality

### Performance Requirements
- [ ] CPU usage < 10% average
- [ ] Memory usage < 200MB total
- [ ] Startup time < 30 seconds
- [ ] No impact on player primary functions

### Quality Requirements
- [ ] No crashes in 24-hour test
- [ ] Graceful degradation on resource pressure
- [ ] Clean uninstallation process

---

## Timeline Summary

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Environment Preparation | 2-3 hours | SDK built |
| Prometheus Build | 3-4 hours | Environment ready |
| Grafana Build | 4-5 hours | Environment ready |
| Extension Integration | 2-3 hours | Both builds complete |
| Testing & Validation | 2 hours | Integration complete |
| Optimization | 2 hours | Testing complete |
| Documentation | 1-2 hours | All phases complete |

**Total Estimated Time: 16-22 hours**

---

## Next Steps

1. **Immediate Actions**
   - Begin with Prometheus build as it's simpler
   - Set up automated build pipeline
   - Create test dashboards

2. **Future Enhancements**
   - Add alerting capabilities
   - Implement log aggregation
   - Add custom metrics exporters
   - Create player-specific dashboards

3. **Production Considerations**
   - Multi-player deployment strategy
   - Central management interface
   - Backup and recovery procedures

---

## Appendix: Useful Commands

### Download Commands
```bash
# Download Prometheus binary
wget https://github.com/prometheus/prometheus/releases/download/v2.48.0/prometheus-2.48.0.linux-arm64.tar.gz

# Download Grafana binary
wget https://dl.grafana.com/oss/release/grafana-10.2.3.linux-arm64.tar.gz

# Package extension using Makefile
make playerbuild
```

### Testing Commands
```bash
# Check processes
ps | grep -E "prometheus|grafana"

# Check ports
netstat -tlnp | grep -E "9090|3000"

# View logs
tail -f /var/log/messages | grep -E "prometheus|grafana"
```

### Debugging Commands
```bash
# Manual start for debugging
./prometheus --config.file=prometheus.yml --log.level=debug
./grafana-server --config=grafana.ini --debug

# Check metrics endpoint
curl http://localhost:9100/metrics
curl http://localhost:9090/api/v1/targets
```