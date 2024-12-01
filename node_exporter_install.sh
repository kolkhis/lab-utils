#!/bin/bash

NODE_EXPORTER_DIR="/opt/node_exporter"
NODE_EXPORTER_VERSION="1.8.2"
NODE_EXPORTER_TARBALL="node_exporter-${NODE_EXPORTER_VERSION}-linux-amd64.tar.gz"
NODE_EXPORTER_EXTRACTED_DIR="${NODE_EXPORTER_DIR}/node_exporter-${NODE_EXPORTER_VERSION}-linux-amd64"
NODE_EXPORTER_BIN_DIR="/usr/sbin"
NODE_EXPORTER_USER="node_exporter"

mkdir -p "${NODE_EXPORTER_DIR}"

curl -L -o "${NODE_EXPORTER_DIR}/${NODE_EXPORTER_TARBALL}" \
    "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}-linux-amd64.tar.gz"

tar -xvzf "${NODE_EXPORTER_DIR}/${NODE_EXPORTER_TARBALL}" -C "${NODE_EXPORTER_DIR}"

git clone https://github.com/prometheus/node_exporter.git \
    "${NODE_EXPORTER_EXTRACTED_DIR}/config_files"






