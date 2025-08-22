# DEMO ONLY - BrightSign Extension with Prometheus and Grafana

This builds an extension that has Prometheus and Grafana installed, configured to collect metrics from the local player only.  This allows demonstration of the players Promehteus Node Exporter (PNE) without needing a separate computer.

## Overall Instructions

Follow the directions in this repo to create a BrightSign extension.  Place all needed binaries in the appropriate locations and all needed config files inthe appropriate locations.  Modify the extension startup scripts to start the required binaries using those configuration files.  Use default credentials whereever credentials are required.


## Prometheus

Source location:  https://github.com/prometheus

Instructions:
1. clone the repo
2. Analyze the build instructions in the repo
3. Build it
4, Create a configuration file to scrape from localhost on the default Prometheus Node Exporter port
5. Install it in the extension locations as described in the Overall Instructions above

## Grafana

Source location: https://github.com/grafana/grafana

Instructions:
1. clone the repo
2. Analyze the build instructions in the repo
3. Build it
4. Install it in the extension locations as described in the Overall Instructions above
