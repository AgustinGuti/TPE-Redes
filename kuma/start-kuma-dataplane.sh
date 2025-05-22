#!/bin/bash

SERVICE_NAME=$1
SERVICE_IP=$2
PORT=$3
DATAPLANE_FILE=$4
TOKEN_FILE=$5
CONTAINER_NAME="kuma-${SERVICE_NAME}"
KUMA_VERSION="2.10.1"
KUMA_CP_ADDRESS="https://control-plane:5678"

if [ -z "$SERVICE_NAME" ] || [ -z "$SERVICE_IP" ] || [ -z "$PORT" ] || [ -z "$DATAPLANE_FILE" ] || [ -z "$TOKEN_FILE" ]; then
  echo "Usage: $0 <service-name> <service-ip> <port> <dataplane.yaml path> <token path>"
  exit 1
fi


echo "📦 Installing tools in container ${CONTAINER_NAME}..."
docker exec -it --privileged --user root "${CONTAINER_NAME}" bash -c "
  set -ex; \
  apt-get update && echo 'Updated package lists' && \
  apt-get install -y curl iptables && echo 'Installed curl and iptables' && \
  cd /tmp && \
  curl --location https://kuma.io/installer.sh -o installer.sh && echo 'Downloaded installer script' && \
  VERSION=\"2.10.1\" bash -x installer.sh || echo 'Installer script failed but continuing' && \
  mv kuma-2.10.1/bin/* /usr/local/bin/ && echo 'Moved Kuma binaries' && \
  useradd --uid 5678 --user-group kuma-data-plane-proxy && echo 'Created kuma-data-plane-proxy user'
"


echo "🚀 Starting kuma-dp in ${CONTAINER_NAME}..."
docker exec -d --privileged --user root "${CONTAINER_NAME}" bash -c "
  runuser --user kuma-data-plane-proxy -- \
    /usr/local/bin/kuma-dp run \
      --cp-address '${KUMA_CP_ADDRESS}' \
      --dataplane-token-file '/kuma/${TOKEN_FILE}' \
      --dataplane-file '/kuma/${DATAPLANE_FILE}' \
      --dataplane-var name='${SERVICE_NAME}' \
      --dataplane-var address='${SERVICE_IP}' \
      --dataplane-var port='${PORT}' \
      > /kuma/logs/logs-data-plane-proxy-${SERVICE_NAME}.log 2>&1
"

echo "🧱 Installing transparent proxy for ${SERVICE_NAME}..."
docker exec -d --privileged --user root "${CONTAINER_NAME}" bash -c "
  kumactl install transparent-proxy \
    --config-file /kuma/config-transparent-proxy.yaml \
    > /kuma/logs/logs-transparent-proxy-install-${SERVICE_NAME}.log 2>&1
"

echo "✅ Kuma dataplane for ${SERVICE_NAME} configured!"
