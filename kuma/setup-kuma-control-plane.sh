#!/bin/bash
set -e

NETWORK_NAME="kuma-app-network"
SUBNET="192.168.0.0/24"
GATEWAY="192.168.0.254"
CONTROL_PLANE_NAME="kuma-demo-control-plane"
CONTROL_PLANE_HOST="control-plane"
CONTROL_PLANE_IP="192.168.0.1"
KUMA_VERSION="2.10.1"
CONTROL_PLANE_PORT=5681
HOST_PORT=25681

echo "🌐 Creating Docker network (${NETWORK_NAME})..."
if docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
  echo "ℹ️ Network ${NETWORK_NAME} already exists. Skipping."
else
  docker network create \
    --subnet "$SUBNET" \
    --gateway "$GATEWAY" \
    "$NETWORK_NAME"
fi

echo "🚀 Starting Kuma Control Plane container..."
if docker ps -a --format '{{.Names}}' | grep -w "$CONTROL_PLANE_NAME" >/dev/null; then
  echo "ℹ️ Control plane container '${CONTROL_PLANE_NAME}' already exists. Recreating it..."
  docker rm -f "$CONTROL_PLANE_NAME"
fi

docker run \
  --detach \
  --name "$CONTROL_PLANE_NAME" \
  --hostname "$CONTROL_PLANE_HOST" \
  --network "$NETWORK_NAME" \
  --ip "$CONTROL_PLANE_IP" \
  --publish "${HOST_PORT}:${CONTROL_PLANE_PORT}" \
  --volume "$(pwd):/control_plane" \
  "kumahq/kuma-cp:${KUMA_VERSION}" run

echo "⏳ Waiting for control plane to be ready..."
sleep 5

echo "🔐 Retrieving admin token..."
KUMA_ADMIN_TOKEN=$(
  docker exec --tty --interactive "$CONTROL_PLANE_NAME" \
    wget --quiet --output-document - \
    http://127.0.0.1:5681/global-secrets/admin-user-token \
    | jq --raw-output .data \
    | base64 --decode
)

echo "🔧 Configuring kumactl..."
kumactl config control-planes add \
  --name "$NETWORK_NAME" \
  --address "http://127.0.0.1:${HOST_PORT}" \
  --auth-type tokens \
  --auth-conf "token=$KUMA_ADMIN_TOKEN" \
  --overwrite \
  --skip-verify

echo "📡 Setting up default mesh config..."
echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive' | kumactl apply -f -

echo "✅ Control plane setup complete."
