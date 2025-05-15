#!/bin/bash


# ──────────────── Arguments ────────────────
SERVICE_NAME=$1
SERVICE_IP=$2
SERVICE_PORT=$3
DB_IP=$4
DB_PORT=$5

# ──────────────── Validation ────────────────
if [ $# -lt 5 ]; then
  echo "Usage: $0 <service-name> <service-ip> <service-port> <db-ip> <db-port>"
  exit 1
fi

# ──────────────── Constants ────────────────
IMAGE_TAG="${SERVICE_NAME}-img"
CONTAINER_NAME="kuma-${SERVICE_NAME}"
DB_NAME="${SERVICE_NAME}-db"
DB_CONTAINER="kuma-${DB_NAME}"
DB_IMAGE="postgres:15"

SERVICE_DIR="${SERVICE_NAME}"

TOKEN_DIR="./tokens"
NETWORK="kuma-app-network"

SERVICE_TOKEN="${TOKEN_DIR}/token-${SERVICE_NAME}"
DB_TOKEN="${TOKEN_DIR}/token-${DB_NAME}"

SERVICE_DATAPLANE="./dataplane-${SERVICE_NAME}.yaml"
DB_DATAPLANE="./dataplane-${DB_NAME}.yaml"

mkdir -p "$TOKEN_DIR" "./logs"

# ──────────────── Generate Tokens ────────────────
echo "🔐 Generating dataplane tokens..."
kumactl generate dataplane-token \
  --tag "kuma.io/service=${SERVICE_NAME}" \
  --valid-for 720h \
  > "$SERVICE_TOKEN"

kumactl generate dataplane-token \
  --tag "kuma.io/service=${DB_NAME}" \
  --valid-for 720h \
  > "$DB_TOKEN"

# ──────────────── Build Service Image ────────────────

# docker build --tag "${IMAGE_TAG}" --file "../$SERVICE_DIR/Dockerfile" "../$SERVICE_DIR"

# CONTAINER_NAME="kuma-${SERVICE_NAME}"
# DB_CONTAINER_NAME="kuma-${SERVICE_NAME}-db"

# # Remove existing containers if they exist
# echo "🧹 Cleaning up existing containers if needed..."

# for container in "$CONTAINER_NAME" "$DB_CONTAINER_NAME"; do
#   if docker ps -a -q -f name="^/${container}$" >/dev/null; then
#     echo "🗑️  Removing existing container $container"
#     docker rm -f "$container"
#   fi
# done

# ──────────────── Start DB ────────────────
echo "🗄️  Starting DB container ${DB_CONTAINER}..."
docker inspect "$DB_CONTAINER" >/dev/null 2>&1 || \
docker run -d \
  --name "$DB_CONTAINER" \
  --hostname "$DB_NAME" \
  --network "$NETWORK" \
  --ip "$DB_IP" \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=userdata \
  --volume "$(pwd):/kuma" \
  "$DB_IMAGE"


sleep 1

# ──────────────── Start Service ────────────────
echo "🚀 Starting service container ${CONTAINER_NAME}..."
docker run -d \
  --name "${CONTAINER_NAME}" \
  --hostname "${SERVICE_NAME}" \
  --network "$NETWORK" \
  --ip "${SERVICE_IP}" \
  -e DATABASE_URL="postgresql://myuser:mypassword@${DB_NAME}:${DB_PORT}/userdata" \
  --volume "$(pwd):/kuma" \
  "${IMAGE_TAG}"

# ──────────────── Start Dataplanes ────────────────
echo "⚙️  Starting kuma-dp for DB..."
sleep 5

./start-kuma-dataplane.sh "$DB_NAME" "$DB_IP" "$DB_PORT" "$DB_DATAPLANE" "$DB_TOKEN"

echo "⚙️  Starting kuma-dp for Service..."
./start-kuma-dataplane.sh "$SERVICE_NAME" "$SERVICE_IP" "$SERVICE_PORT" "$SERVICE_DATAPLANE" "$SERVICE_TOKEN"

echo "✅ ${SERVICE_NAME} and ${DB_NAME} deployed with dataplanes!"
