#!/bin/bash

# get script directory
script_dir=$(dirname "$(realpath "$0")")

# shift to target directory to squash
cd $1

${script_dir}/make-extension-$2

# Create zip package with all necessary files
zip -j ../monitoring-$(date +%s).zip monitoring.squashfs monitoring_install-*.sh

# Clean up temporary files
rm -f monitoring.squashfs monitoring_install-*.sh