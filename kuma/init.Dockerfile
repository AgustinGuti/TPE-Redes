FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && \
    apt-get install -y curl wget jq iptables && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Kuma using the official installer
RUN cd /tmp && \
    curl --location https://kuma.io/installer.sh -o installer.sh && \
    VERSION="2.10.1" bash installer.sh && \
    mv kuma-2.10.1/bin/* /usr/local/bin/ && \
    rm -rf /tmp/kuma* && \
    useradd --uid 5678 --user-group kuma-data-plane-proxy

# Verify installation
RUN kumactl version

# No default entrypoint
ENTRYPOINT []