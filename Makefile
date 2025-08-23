# BrightSign Monitoring Extension Makefile
# Downloads pre-built Prometheus and Grafana binaries and creates monitoring extension for testing and BrightSign players

# Version information
PROMETHEUS_VERSION := 2.48.0
GRAFANA_VERSION := 10.2.3
EXTENSION_NAME := mon
TIMESTAMP := $(shell date +%s)

# Detect host architecture
HOST_ARCH := $(shell uname -m)
HOST_OS := $(shell uname -s | tr '[:upper:]' '[:lower:]')

# Allow forcing architecture for testing (e.g., FORCE_ARCH=amd64 make test-build)
ifdef FORCE_ARCH
    GO_ARCH := $(FORCE_ARCH)
    ARCH_SUFFIX := $(FORCE_ARCH)
else
    # Map architecture names to Go/Prometheus conventions
    ifeq ($(HOST_ARCH),x86_64)
        GO_ARCH := amd64
        ARCH_SUFFIX := amd64
    else ifeq ($(HOST_ARCH),aarch64)
        GO_ARCH := arm64
        ARCH_SUFFIX := arm64
    else ifeq ($(HOST_ARCH),arm64)
        GO_ARCH := arm64
        ARCH_SUFFIX := arm64
    else
        GO_ARCH := $(HOST_ARCH)
        ARCH_SUFFIX := $(HOST_ARCH)
    endif
endif

# Build mode (test or player)
BUILD_MODE ?= player

# Directories - separate for test and player builds
ifeq ($(BUILD_MODE),test)
    BUILD_DIR := build-test
    INSTALL_DIR := install-test
    OUTPUT_DIR := output-test
    TARGET_ARCH := $(ARCH_SUFFIX)
    TARGET_OS := $(HOST_OS)
else
    BUILD_DIR := build
    INSTALL_DIR := install
    OUTPUT_DIR := output
    TARGET_ARCH := arm64
    TARGET_OS := linux
endif

BINARIES_DIR := $(BUILD_DIR)/binaries
CONFIG_DIR := configs
SCRIPTS_DIR := sh

# URLs for binaries based on target architecture
PROMETHEUS_URL_ARM64 := https://github.com/prometheus/prometheus/releases/download/v$(PROMETHEUS_VERSION)/prometheus-$(PROMETHEUS_VERSION).linux-arm64.tar.gz
GRAFANA_URL_ARM64 := https://dl.grafana.com/oss/release/grafana-$(GRAFANA_VERSION).linux-arm64.tar.gz

PROMETHEUS_URL_AMD64 := https://github.com/prometheus/prometheus/releases/download/v$(PROMETHEUS_VERSION)/prometheus-$(PROMETHEUS_VERSION).linux-amd64.tar.gz
GRAFANA_URL_AMD64 := https://dl.grafana.com/oss/release/grafana-$(GRAFANA_VERSION).linux-amd64.tar.gz

PROMETHEUS_URL_DARWIN_AMD64 := https://github.com/prometheus/prometheus/releases/download/v$(PROMETHEUS_VERSION)/prometheus-$(PROMETHEUS_VERSION).darwin-amd64.tar.gz
GRAFANA_URL_DARWIN_AMD64 := https://dl.grafana.com/oss/release/grafana-$(GRAFANA_VERSION).darwin-amd64.tar.gz

PROMETHEUS_URL_DARWIN_ARM64 := https://github.com/prometheus/prometheus/releases/download/v$(PROMETHEUS_VERSION)/prometheus-$(PROMETHEUS_VERSION).darwin-arm64.tar.gz
GRAFANA_URL_DARWIN_ARM64 := https://dl.grafana.com/oss/release/grafana-$(GRAFANA_VERSION).darwin-arm64.tar.gz

# Select URLs based on target
ifeq ($(BUILD_MODE),test)
    # For test builds, check if we're forcing a specific architecture
    ifdef FORCE_ARCH
        # When forcing arch, assume Linux binaries for container testing
        ifeq ($(FORCE_ARCH),amd64)
            PROMETHEUS_URL := $(PROMETHEUS_URL_AMD64)
            GRAFANA_URL := $(GRAFANA_URL_AMD64)
        else ifeq ($(FORCE_ARCH),arm64)
            PROMETHEUS_URL := $(PROMETHEUS_URL_ARM64)
            GRAFANA_URL := $(GRAFANA_URL_ARM64)
        endif
    else
        # Auto-detect based on host OS
        ifeq ($(HOST_OS),darwin)
            ifeq ($(GO_ARCH),arm64)
                PROMETHEUS_URL := $(PROMETHEUS_URL_DARWIN_ARM64)
                GRAFANA_URL := $(GRAFANA_URL_DARWIN_ARM64)
            else
                PROMETHEUS_URL := $(PROMETHEUS_URL_DARWIN_AMD64)
                GRAFANA_URL := $(GRAFANA_URL_DARWIN_AMD64)
            endif
        else
            ifeq ($(GO_ARCH),arm64)
                PROMETHEUS_URL := $(PROMETHEUS_URL_ARM64)
                GRAFANA_URL := $(GRAFANA_URL_ARM64)
            else
                PROMETHEUS_URL := $(PROMETHEUS_URL_AMD64)
                GRAFANA_URL := $(GRAFANA_URL_AMD64)
            endif
        endif
    endif
else
    # Player build always uses ARM64 Linux
    PROMETHEUS_URL := $(PROMETHEUS_URL_ARM64)
    GRAFANA_URL := $(GRAFANA_URL_ARM64)
endif

# Output files
SQUASHFS_FILE := $(OUTPUT_DIR)/ext_$(EXTENSION_NAME).squashfs
INSTALL_SCRIPT_LVM := $(OUTPUT_DIR)/ext_$(EXTENSION_NAME)_install-lvm.sh
# Package file is always zip format
PACKAGE_FILE := $(OUTPUT_DIR)/ext_$(EXTENSION_NAME)-$(TIMESTAMP).zip

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

# Default target (player build)
.PHONY: all
all: player-build

# Test build for local architecture
.PHONY: test-build
test-build:
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)Building for TEST (Local Architecture)$(NC)"
	@echo "Host: $(HOST_OS)/$(HOST_ARCH)"
	@echo "Target Arch: $(GO_ARCH)"
	@if [ -n "$(FORCE_ARCH)" ]; then \
		echo "$(YELLOW)Forced Architecture: $(FORCE_ARCH) (Linux binaries for container)$(NC)"; \
	fi
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"
	@$(MAKE) BUILD_MODE=test clean prepare download configure test-package
	@echo "$(GREEN)✓ Test build complete!$(NC)"
	@echo ""
	@echo "$(YELLOW)To test locally:$(NC)"
	@echo "  1. Mount the extension: make test-mount"
	@echo "  2. Start services: make test-start"
	@echo "  3. Access Prometheus: http://localhost:9090 (configurable via registry: mon-prometheus-port)"
	@echo "  4. Access Grafana: http://localhost:3000 (configurable via registry: mon-grafana-port)"
	@echo "  5. Stop services: make test-stop"
	@echo "  6. Unmount: make test-unmount"

# Player build for ARM64 BrightSign
.PHONY: player-build
player-build:
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)Building for PLAYER (ARM64 BrightSign)$(NC)"
	@echo "Target: linux/arm64"
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"
	@$(MAKE) BUILD_MODE=player clean prepare download configure package
	@echo "$(GREEN)✓ Player build complete!$(NC)"
	@echo "Package: $(PACKAGE_FILE)"

# Help target
.PHONY: help
help:
	@echo "$(YELLOW)BrightSign Monitoring Extension Builder$(NC)"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "$(GREEN)Build Modes:$(NC)"
	@echo "  test-build   - Build for local testing ($(HOST_OS)/$(HOST_ARCH))"
	@echo "  player-build - Build for BrightSign player (linux/arm64)"
	@echo "  all          - Same as player-build (default)"
	@echo ""
	@echo "$(GREEN)Test Mode Commands:$(NC)"
	@echo "  test-mount   - Mount test build locally"
	@echo "  test-start   - Start services locally"
	@echo "  test-stop    - Stop services"
	@echo "  test-unmount - Unmount test build"
	@echo "  test-status  - Check service status"
	@echo "  test-logs    - View service logs"
	@echo ""
	@echo "$(GREEN)Common targets:$(NC)"
	@echo "  download     - Download binaries for current mode"
	@echo "  configure    - Setup configuration files"
	@echo "  package      - Create final package"
	@echo "  clean        - Remove build artifacts"
	@echo "  distclean    - Remove everything including downloads"
	@echo ""
	@echo "$(GREEN)Individual targets:$(NC)"
	@echo "  prometheus   - Download and setup Prometheus only"
	@echo "  grafana      - Download and setup Grafana only"
	@echo "  verify       - Verify binary architecture"
	@echo ""
	@echo "$(GREEN)Current Configuration:$(NC)"
	@echo "  PROMETHEUS_VERSION = $(PROMETHEUS_VERSION)"
	@echo "  GRAFANA_VERSION    = $(GRAFANA_VERSION)"
	@echo "  HOST_ARCH          = $(HOST_ARCH) ($(GO_ARCH))"
	@echo "  HOST_OS            = $(HOST_OS)"

# Prepare directories
.PHONY: prepare
prepare:
	@echo "$(YELLOW)→ Preparing directories...$(NC)"
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BINARIES_DIR)
	@mkdir -p $(INSTALL_DIR)
	@mkdir -p $(OUTPUT_DIR)
	@mkdir -p $(INSTALL_DIR)/prometheus/data
	@mkdir -p $(INSTALL_DIR)/grafana/data
	@mkdir -p $(INSTALL_DIR)/grafana/conf/provisioning/datasources
	@mkdir -p $(INSTALL_DIR)/grafana/conf/provisioning/dashboards
	@echo "$(GREEN)✓ Directories created$(NC)"

# Download all binaries
.PHONY: download
download: prometheus grafana
	@echo "$(GREEN)✓ All binaries downloaded$(NC)"

# Download and extract Prometheus pre-built binary
.PHONY: prometheus
prometheus: prepare
	@echo "$(YELLOW)→ Downloading Prometheus $(PROMETHEUS_VERSION) pre-built binary for $(TARGET_ARCH)...$(NC)"
	@if [ ! -f $(BINARIES_DIR)/prometheus.tar.gz ]; then \
		curl -L -o $(BINARIES_DIR)/prometheus.tar.gz $(PROMETHEUS_URL); \
	fi
	@echo "$(YELLOW)→ Extracting Prometheus...$(NC)"
	@tar -xzf $(BINARIES_DIR)/prometheus.tar.gz --strip-components=1 -C $(INSTALL_DIR)/prometheus
	@echo "$(GREEN)✓ Prometheus ready$(NC)"

# Download and extract Grafana pre-built binary
.PHONY: grafana
grafana: prepare
	@echo "$(YELLOW)→ Downloading Grafana $(GRAFANA_VERSION) pre-built binary for $(TARGET_ARCH)...$(NC)"
	@if [ ! -f $(BINARIES_DIR)/grafana.tar.gz ]; then \
		curl -L -o $(BINARIES_DIR)/grafana.tar.gz $(GRAFANA_URL); \
	fi
	@echo "$(YELLOW)→ Extracting Grafana...$(NC)"
	@tar -xzf $(BINARIES_DIR)/grafana.tar.gz --strip-components=1 -C $(INSTALL_DIR)/grafana
	@echo "$(GREEN)✓ Grafana ready$(NC)"

# Configure services
.PHONY: configure
configure: prepare
	@echo "$(YELLOW)→ Configuring services...$(NC)"
	@cp $(CONFIG_DIR)/prometheus/prometheus.yml $(INSTALL_DIR)/prometheus/
	@cp $(CONFIG_DIR)/grafana/grafana.ini $(INSTALL_DIR)/grafana/conf/
	@cp $(CONFIG_DIR)/grafana/provisioning/datasources/*.yaml $(INSTALL_DIR)/grafana/conf/provisioning/datasources/
	@cp $(CONFIG_DIR)/grafana/provisioning/dashboards/*.yaml $(INSTALL_DIR)/grafana/conf/provisioning/dashboards/ 2>/dev/null || true
	@cp $(CONFIG_DIR)/grafana/provisioning/dashboards/*.json $(INSTALL_DIR)/grafana/conf/provisioning/dashboards/ 2>/dev/null || true
	@cp $(SCRIPTS_DIR)/bsext_init $(INSTALL_DIR)/
	@cp $(SCRIPTS_DIR)/uninstall.sh $(INSTALL_DIR)/
	@chmod +x $(INSTALL_DIR)/bsext_init
	@chmod +x $(INSTALL_DIR)/uninstall.sh
	@echo "$(GREEN)✓ Configuration complete$(NC)"

# Create squashfs filesystem
.PHONY: squashfs
squashfs: configure
	@echo "$(YELLOW)→ Creating squashfs filesystem...$(NC)"
	@if ! command -v mksquashfs >/dev/null 2>&1; then \
		echo "$(RED)✗ Error: squashfs-tools not installed$(NC)"; \
		echo "Please install squashfs-tools:"; \
		echo "  Ubuntu/Debian: sudo apt-get install squashfs-tools"; \
		echo "  RHEL/CentOS: sudo yum install squashfs-tools"; \
		echo "  macOS: brew install squashfs"; \
		exit 1; \
	fi
	@mksquashfs $(INSTALL_DIR) $(SQUASHFS_FILE) -comp gzip -noappend
	@echo "$(GREEN)✓ Squashfs created$(NC)"

# Generate installation scripts
.PHONY: scripts
scripts: squashfs
	@echo "$(YELLOW)→ Generating installation script...$(NC)"
	@$(MAKE) -s generate-lvm-script
	@echo "$(GREEN)✓ Installation script created$(NC)"

# Generate LVM installation script (fully hardcoded like NPU gaze)
.PHONY: generate-lvm-script
generate-lvm-script:
	@echo "$(YELLOW)→ Calculating hardcoded values for installation script...$(NC)"
	@IMAGE_SIZE=$$(if stat --format=%s $(SQUASHFS_FILE) 2>/dev/null >/dev/null; then stat --format=%s $(SQUASHFS_FILE); else stat -f %z $(SQUASHFS_FILE); fi) && \
	VOLUME_SIZE=$$((($$IMAGE_SIZE + 4096 + 511) / 512 * 512)) && \
	IMAGE_SIZE_PAGES=$$(($$IMAGE_SIZE / 4096)) && \
	SHA256=$$( (cat $(SQUASHFS_FILE) && dd if=/dev/zero bs=4096 count=1 2>/dev/null) | dd bs=4096 count=$$IMAGE_SIZE_PAGES 2>/dev/null | if sha256sum --version 2>/dev/null >/dev/null; then sha256sum | cut -c1-64; else shasum -a 256 | cut -c1-64; fi ) && \
	echo "  Image Size: $$IMAGE_SIZE bytes" && \
	echo "  Volume Size: $$VOLUME_SIZE bytes" && \
	echo "  Image Pages: $$IMAGE_SIZE_PAGES pages" && \
	echo "  SHA256: $$SHA256" && \
	echo '#!/bin/sh' > $(INSTALL_SCRIPT_LVM) && \
	echo '# This install script is only useful during development.' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'set -xe' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'echo "Trying to unmount $(EXTENSION_NAME) volume"' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'if [ -d '\''/var/volatile/bsext/ext_$(EXTENSION_NAME)'\'' ]; then' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    umount /var/volatile/bsext/ext_$(EXTENSION_NAME)' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    rmdir /var/volatile/bsext/ext_$(EXTENSION_NAME)' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo '# Remove dm-verity mapping' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'if [ -b '\''/dev/mapper/bsos-ext_$(EXTENSION_NAME)-verified'\'' ]; then' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    veritysetup close '\''bsos-ext_$(EXTENSION_NAME)-verified'\''' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo '# Remove old volumes' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'if [ -b '\''/dev/mapper/bsos-ext_$(EXTENSION_NAME)'\'' ]; then' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    lvremove --yes '\''/dev/mapper/bsos-ext_$(EXTENSION_NAME)'\''' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    rm -f '\''/dev/mapper/bsos-ext_$(EXTENSION_NAME)'\''' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'if [ -b '\''/dev/mapper/bsos-tmp_$(EXTENSION_NAME)'\'' ]; then' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    lvremove --yes '\''/dev/mapper/bsos-tmp_$(EXTENSION_NAME)'\''' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    rm -f '\''/dev/mapper/bsos-tmp_$(EXTENSION_NAME)'\''' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo '# Clean up any broken volumes from previous attempts' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'if [ -b '\''/dev/mapper/bsos-ext_'\'' ]; then' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    echo "Cleaning up broken volumes from previous attempts"' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    lvremove --yes '\''/dev/mapper/bsos-ext_'\'' || true' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    rm -f '\''/dev/mapper/bsos-ext_'\'' || true' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'if [ -b '\''/dev/mapper/bsos-tmp_ext_'\'' ]; then' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    lvremove --yes '\''/dev/mapper/bsos-tmp_ext_'\'' || true' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    rm -f '\''/dev/mapper/bsos-tmp_ext_'\'' || true' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo "lvcreate --yes --size $${VOLUME_SIZE}b -n 'tmp_$(EXTENSION_NAME)' bsos" >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'echo Writing image to tmp_$(EXTENSION_NAME) volume...' >> $(INSTALL_SCRIPT_LVM) && \
	echo '(cat ext_$(EXTENSION_NAME).squashfs && dd if=/dev/zero bs=4096 count=1) > /dev/mapper/bsos-tmp_$(EXTENSION_NAME)' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo "check=\"\`dd 'if=/dev/mapper/bsos-tmp_$(EXTENSION_NAME)' bs=4096 count=$$IMAGE_SIZE_PAGES 2>/dev/null | sha256sum | cut -c-64\`\"" >> $(INSTALL_SCRIPT_LVM) && \
	echo "if [ \"\$$check\" != \"$$SHA256\" ]; then" >> $(INSTALL_SCRIPT_LVM) && \
	echo '    echo "VERIFY FAILURE for tmp_$(EXTENSION_NAME) volume"' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    lvremove --yes '\''/dev/mapper/bsos-tmp_$(EXTENSION_NAME)'\'' || true' >> $(INSTALL_SCRIPT_LVM) && \
	echo '    exit 4' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'fi' >> $(INSTALL_SCRIPT_LVM) && \
	echo '' >> $(INSTALL_SCRIPT_LVM) && \
	echo 'lvrename bsos '\''tmp_$(EXTENSION_NAME)'\'' '\''ext_$(EXTENSION_NAME)'\''' >> $(INSTALL_SCRIPT_LVM)
	@chmod +x $(INSTALL_SCRIPT_LVM)


# Package everything
.PHONY: package
package: scripts
	@echo "$(YELLOW)→ Creating final package...$(NC)"
	@cd $(OUTPUT_DIR) && zip -j ext_$(EXTENSION_NAME)-$(TIMESTAMP).zip \
		ext_$(EXTENSION_NAME).squashfs \
		ext_$(EXTENSION_NAME)_install-lvm.sh
	@$(MAKE) -s generate-readme
	@echo "$(GREEN)✓ Package created: $(PACKAGE_FILE)$(NC)"
	@echo ""
	@$(MAKE) -s show-summary

# Generate README
.PHONY: generate-readme
generate-readme:
	@echo "# BrightSign Mon Extension" > $(OUTPUT_DIR)/README.md
	@echo "" >> $(OUTPUT_DIR)/README.md
	@echo "## Package Information" >> $(OUTPUT_DIR)/README.md
	@echo "- Build Date: $(shell date)" >> $(OUTPUT_DIR)/README.md
	@echo "- Prometheus: $(PROMETHEUS_VERSION)" >> $(OUTPUT_DIR)/README.md
	@echo "- Grafana: $(GRAFANA_VERSION)" >> $(OUTPUT_DIR)/README.md
	@echo "- Architecture: ARM64/AArch64" >> $(OUTPUT_DIR)/README.md
	@echo "" >> $(OUTPUT_DIR)/README.md
	@echo "## Installation" >> $(OUTPUT_DIR)/README.md
	@echo '```bash' >> $(OUTPUT_DIR)/README.md
	@echo "# Copy to player" >> $(OUTPUT_DIR)/README.md
	@echo "scp ext_$(EXTENSION_NAME)-*.zip brightsign@player:/storage/sd/" >> $(OUTPUT_DIR)/README.md
	@echo "" >> $(OUTPUT_DIR)/README.md
	@echo "# Install on player" >> $(OUTPUT_DIR)/README.md
	@echo "unzip ext_$(EXTENSION_NAME)-*.zip" >> $(OUTPUT_DIR)/README.md
	@echo "bash ./ext_$(EXTENSION_NAME)_install-lvm.sh" >> $(OUTPUT_DIR)/README.md
	@echo "reboot" >> $(OUTPUT_DIR)/README.md
	@echo '```' >> $(OUTPUT_DIR)/README.md

# Show build summary
.PHONY: show-summary
show-summary:
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"
	@echo "$(GREEN)        Build Summary$(NC)"
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"
	@echo "Extension Name:     $(EXTENSION_NAME)"
	@echo "Prometheus Version: $(PROMETHEUS_VERSION)"
	@echo "Grafana Version:    $(GRAFANA_VERSION)"
	@ACTUAL_PACKAGE=$$(ls $(OUTPUT_DIR)/ext_$(EXTENSION_NAME)-*.zip 2>/dev/null | head -1) && \
	if [ -f "$$ACTUAL_PACKAGE" ]; then \
		echo "Package File:       $$ACTUAL_PACKAGE"; \
		echo "Package Size:       $$(du -h $$ACTUAL_PACKAGE | cut -f1)"; \
	else \
		echo "Package File:       $(PACKAGE_FILE) (not found)"; \
		echo "Package Size:       N/A"; \
	fi
	@echo "Install Size:       $$(du -sh $(INSTALL_DIR) | cut -f1)"
	@echo ""
	@echo "$(GREEN)Next Steps:$(NC)"
	@ACTUAL_PACKAGE=$$(ls $(OUTPUT_DIR)/ext_$(EXTENSION_NAME)-*.zip 2>/dev/null | head -1) && \
	if [ -f "$$ACTUAL_PACKAGE" ]; then \
		echo "1. Transfer $$ACTUAL_PACKAGE to BrightSign player"; \
		echo "2. Extract and run installation script"; \
		echo "3. Reboot player to activate monitoring"; \
	else \
		echo "1. Package file not found - check build output"; \
	fi
	@echo ""
	@echo "Web Interfaces:"
	@echo "  Prometheus: http://player:9090 (configurable via registry: mon-prometheus-port)"
	@echo "  Grafana:    http://player:3000 (admin/admin, configurable via registry: mon-grafana-port)"
	@echo "$(YELLOW)════════════════════════════════════════════════$(NC)"

# Verify ARM64 binaries
.PHONY: verify
verify:
	@echo "$(YELLOW)→ Verifying ARM64 binaries...$(NC)"
	@if command -v readelf >/dev/null 2>&1; then \
		echo "Prometheus: $$(readelf -h $(INSTALL_DIR)/prometheus/prometheus | grep Machine)"; \
		echo "Grafana:    $$(readelf -h $(INSTALL_DIR)/grafana/bin/grafana-server | grep Machine)"; \
	else \
		echo "readelf not available, checking with strings..."; \
		strings $(INSTALL_DIR)/prometheus/prometheus | grep -i aarch64 | head -1 || echo "Prometheus: ARM64 (assumed)"; \
		strings $(INSTALL_DIR)/grafana/bin/grafana-server | grep -i aarch64 | head -1 || echo "Grafana: ARM64 (assumed)"; \
	fi
	@echo "$(GREEN)✓ Verification complete$(NC)"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "$(YELLOW)→ Cleaning build artifacts...$(NC)"
	@rm -rf $(OUTPUT_DIR)
	@rm -rf $(INSTALL_DIR)
	@echo "$(YELLOW)→ Removing all zip and squashfs files...$(NC)"
	@rm -f *.tar.gz
	@rm -f *.squashfs
	@rm -f *.zip
	@rm -f ext_monitoring*.zip
	@rm -f ext_monitoring_install*.sh
	@rm -f PACKAGE_CONTENTS.txt
	@rm -f BUILD_SUMMARY.md
	@rm -f DEPLOYMENT.md
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Clean all builds (both test and player)
.PHONY: clean-all
clean-all:
	@echo "$(YELLOW)→ Cleaning all build artifacts (test and player)...$(NC)"
	@rm -rf output output-test
	@rm -rf install install-test
	@rm -rf build build-test
	@$(MAKE) test-stop 2>/dev/null || true
	@$(MAKE) test-unmount 2>/dev/null || true
	@rm -f *.tar.gz *.squashfs *.zip
	@rm -f ext_monitoring*.zip ext_monitoring_install*.sh
	@echo "$(GREEN)✓ All builds cleaned$(NC)"

# Deep clean including downloads
.PHONY: distclean
distclean: clean-all
	@echo "$(YELLOW)→ Removing all downloaded files...$(NC)"
	@rm -rf build build-test
	@echo "$(GREEN)✓ Distribution clean complete$(NC)"

# Test targets
.PHONY: test
test:
	@echo "$(YELLOW)→ Running tests...$(NC)"
	@echo "Checking for required tools..."
	@command -v curl >/dev/null 2>&1 && echo "✓ curl found" || echo "✗ curl not found"
	@command -v tar >/dev/null 2>&1 && echo "✓ tar found" || echo "✗ tar not found"
	@command -v mksquashfs >/dev/null 2>&1 && echo "✓ mksquashfs found" || echo "✗ mksquashfs not found (REQUIRED)"
	@echo ""
	@echo "Checking directories..."
	@test -d $(CONFIG_DIR) && echo "✓ Config directory exists" || echo "✗ Config directory missing"
	@test -d $(SCRIPTS_DIR) && echo "✓ Scripts directory exists" || echo "✗ Scripts directory missing"
	@test -f $(SCRIPTS_DIR)/bsext_init && echo "✓ Init script exists" || echo "✗ Init script missing"
	@echo "$(GREEN)✓ Tests complete$(NC)"

# Test build package (no squashfs, direct directory)
.PHONY: test-package
test-package:
	@echo "$(YELLOW)→ Creating test package...$(NC)"
	@echo "Test build ready in: $(INSTALL_DIR)"
	@echo "$(GREEN)✓ Test package complete$(NC)"

# Mount test build locally (simulates BrightSign mount)
.PHONY: test-mount
test-mount:
	@echo "$(YELLOW)→ Mounting test build...$(NC)"
	@if [ ! -d "install-test" ]; then \
		echo "$(RED)✗ Test build not found. Run 'make test-build' first$(NC)"; \
		exit 1; \
	fi
	@mkdir -p /tmp/bsext/ext_mon
	@if mountpoint -q /tmp/bsext/ext_mon; then \
		echo "$(YELLOW)Already mounted. Run 'make test-unmount' first$(NC)"; \
	else \
		if command -v bindfs >/dev/null 2>&1; then \
			bindfs install-test /tmp/bsext/ext_mon; \
		else \
			sudo mount --bind install-test /tmp/bsext/ext_mon || \
			cp -r install-test/* /tmp/bsext/ext_mon/; \
		fi; \
		echo "$(GREEN)✓ Mounted at /tmp/bsext/ext_mon$(NC)"; \
	fi

# Unmount test build
.PHONY: test-unmount
test-unmount:
	@echo "$(YELLOW)→ Unmounting test build...$(NC)"
	@if mountpoint -q /tmp/bsext/ext_mon; then \
		sudo umount /tmp/bsext/ext_mon || fusermount -u /tmp/bsext/ext_mon; \
	fi
	@rm -rf /tmp/bsext/ext_mon
	@echo "$(GREEN)✓ Unmounted$(NC)"

# Start services for testing
.PHONY: test-start
test-start:
	@echo "$(YELLOW)→ Starting test services...$(NC)"
	@if [ ! -d "/tmp/bsext/ext_mon" ]; then \
		echo "$(RED)✗ Test build not mounted. Run 'make test-mount' first$(NC)"; \
		exit 1; \
	fi
	@echo "Checking binaries..."
	@if [ ! -x "/tmp/bsext/ext_mon/prometheus/prometheus" ]; then \
		echo "$(YELLOW)Making Prometheus executable...$(NC)"; \
		chmod +x /tmp/bsext/ext_mon/prometheus/prometheus 2>/dev/null || true; \
	fi
	@if [ ! -x "/tmp/bsext/ext_mon/grafana/bin/grafana-server" ]; then \
		echo "$(YELLOW)Making Grafana executable...$(NC)"; \
		chmod +x /tmp/bsext/ext_mon/grafana/bin/grafana-server 2>/dev/null || true; \
		chmod +x /tmp/bsext/ext_mon/grafana/bin/grafana 2>/dev/null || true; \
		chmod +x /tmp/bsext/ext_mon/grafana/bin/grafana-cli 2>/dev/null || true; \
	fi
	@echo "Starting Prometheus..."
	@cd /tmp/bsext/ext_mon && \
		nohup ./prometheus/prometheus \
			--config.file=./prometheus/prometheus.yml \
			--storage.tsdb.path=./prometheus/data \
			--web.listen-address=:9090 \
			> /tmp/prometheus.log 2>&1 & \
		echo $$! > /tmp/prometheus.pid
	@sleep 2
	@echo "Starting Grafana..."
	@cd /tmp/bsext/ext_mon/grafana && \
		GF_PATHS_CONFIG=./conf/grafana.ini \
		GF_PATHS_DATA=./data \
		GF_PATHS_HOME=. \
		GF_PATHS_LOGS=./data/logs \
		GF_PATHS_PLUGINS=./plugins \
		GF_PATHS_PROVISIONING=./conf/provisioning \
		nohup ./bin/grafana-server \
			> /tmp/grafana.log 2>&1 & \
		echo $$! > /tmp/grafana.pid
	@sleep 2
	@echo "$(GREEN)✓ Services started$(NC)"
	@echo "  Prometheus: http://localhost:9090"
	@echo "  Grafana: http://localhost:3000 (admin/admin)"
	@echo "  Note: Ports configurable via registry keys (see README.md)"

# Stop test services
.PHONY: test-stop
test-stop:
	@echo "$(YELLOW)→ Stopping test services...$(NC)"
	@if [ -f /tmp/prometheus.pid ]; then \
		kill `cat /tmp/prometheus.pid` 2>/dev/null || true; \
		rm -f /tmp/prometheus.pid; \
		echo "✓ Prometheus stopped"; \
	fi
	@if [ -f /tmp/grafana.pid ]; then \
		kill `cat /tmp/grafana.pid` 2>/dev/null || true; \
		rm -f /tmp/grafana.pid; \
		echo "✓ Grafana stopped"; \
	fi
	@echo "$(GREEN)✓ Services stopped$(NC)"

# Check test service status
.PHONY: test-status
test-status:
	@echo "$(YELLOW)→ Service Status$(NC)"
	@if [ -f /tmp/prometheus.pid ] && kill -0 `cat /tmp/prometheus.pid` 2>/dev/null; then \
		echo "✓ Prometheus: Running (PID: `cat /tmp/prometheus.pid`)"; \
	else \
		echo "✗ Prometheus: Not running"; \
	fi
	@if [ -f /tmp/grafana.pid ] && kill -0 `cat /tmp/grafana.pid` 2>/dev/null; then \
		echo "✓ Grafana: Running (PID: `cat /tmp/grafana.pid`)"; \
	else \
		echo "✗ Grafana: Not running"; \
	fi

# View test service logs
.PHONY: test-logs
test-logs:
	@echo "$(YELLOW)→ Service Logs$(NC)"
	@echo "$(GREEN)Prometheus:$(NC)"
	@tail -n 20 /tmp/prometheus.log 2>/dev/null || echo "No logs available"
	@echo ""
	@echo "$(GREEN)Grafana:$(NC)"
	@tail -n 20 /tmp/grafana.log 2>/dev/null || echo "No logs available"

# Diagnose test issues
.PHONY: test-diagnose
test-diagnose:
	@echo "$(YELLOW)→ Diagnosing Test Build$(NC)"
	@echo ""
	@echo "$(GREEN)Binary Check:$(NC)"
	@file /tmp/bsext/ext_mon/prometheus/prometheus 2>/dev/null || echo "Prometheus binary not found"
	@file /tmp/bsext/ext_mon/grafana/bin/grafana-server 2>/dev/null || echo "Grafana binary not found"
	@echo ""
	@echo "$(GREEN)Permissions:$(NC)"
	@ls -la /tmp/bsext/ext_mon/prometheus/prometheus 2>/dev/null || echo "Prometheus not found"
	@ls -la /tmp/bsext/ext_mon/grafana/bin/grafana-server 2>/dev/null || echo "Grafana not found"
	@echo ""
	@echo "$(GREEN)Architecture:$(NC)"
	@echo "Host: $$(uname -m)"
	@/tmp/bsext/ext_mon/prometheus/prometheus --version 2>&1 | head -1 || echo "Cannot run Prometheus"
	@/tmp/bsext/ext_mon/grafana/bin/grafana-server -v 2>&1 | head -1 || echo "Cannot run Grafana"
	@echo ""
	@echo "$(GREEN)Port Check:$(NC)"
	@netstat -tln 2>/dev/null | grep -E "9090|3000" || echo "No services listening on expected ports"


# Install dependencies (for development systems)
.PHONY: deps
deps:
	@echo "$(YELLOW)→ Installing dependencies...$(NC)"
	@if command -v apt-get >/dev/null 2>&1; then \
		echo "Installing on Debian/Ubuntu..."; \
		sudo apt-get update && sudo apt-get install -y squashfs-tools curl tar; \
	elif command -v yum >/dev/null 2>&1; then \
		echo "Installing on RHEL/CentOS..."; \
		sudo yum install -y squashfs-tools curl tar; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "Installing on macOS..."; \
		brew install squashfs curl; \
	else \
		echo "$(RED)✗ Unable to install dependencies automatically$(NC)"; \
		echo "Please install: squashfs-tools (REQUIRED), curl, tar"; \
	fi

.PHONY: quick
quick: prepare download configure
	@echo "$(YELLOW)→ Quick build (no packaging)...$(NC)"
	@echo "$(GREEN)✓ Binaries ready in $(INSTALL_DIR)$(NC)"

# Development target - rebuild without downloading
.PHONY: rebuild
rebuild:
	@echo "$(YELLOW)→ Rebuilding package...$(NC)"
	@$(MAKE) configure
	@$(MAKE) package
	@echo "$(GREEN)✓ Rebuild complete$(NC)"

# Watch for changes and rebuild
.PHONY: watch
watch:
	@echo "$(YELLOW)→ Watching for changes...$(NC)"
	@while true; do \
		$(MAKE) rebuild; \
		echo "$(GREEN)Waiting for changes... (Ctrl+C to stop)$(NC)"; \
		sleep 5; \
	done

# Print variables (for debugging)
.PHONY: vars
vars:
	@echo "PROMETHEUS_VERSION = $(PROMETHEUS_VERSION)"
	@echo "GRAFANA_VERSION    = $(GRAFANA_VERSION)"
	@echo "EXTENSION_NAME     = $(EXTENSION_NAME)"
	@echo "TIMESTAMP          = $(TIMESTAMP)"
	@echo "BUILD_DIR          = $(BUILD_DIR)"
	@echo "INSTALL_DIR        = $(INSTALL_DIR)"
	@echo "OUTPUT_DIR         = $(OUTPUT_DIR)"
	@echo "PACKAGE_FILE       = $(PACKAGE_FILE)"

# Check squashfs tools availability
.PHONY: check-squashfs
check-squashfs:
	@if ! command -v mksquashfs >/dev/null 2>&1; then \
		echo "$(RED)✗ Error: squashfs-tools not installed$(NC)"; \
		echo "Please install squashfs-tools to continue"; \
		exit 1; \
	fi

# Phony target to force rebuilds
.PHONY: force
force:


# Include any local overrides
-include Makefile.local