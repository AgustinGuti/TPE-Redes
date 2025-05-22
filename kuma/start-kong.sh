#!/bin/bash


# ──────────────── Arguments ────────────────
SERVICE_NAME="kong"
SERVICE_IP="192.168.0.2"
SERVICE_PORT="8001"
DB_IP="192.168.0.12"
DB_PORT="5432" 

# ──────────────── Constants ────────────────
IMAGE_TAG="kong:latest"
CONTAINER_NAME="kuma-kong"
DB_NAME="${SERVICE_NAME}-db"
DB_CONTAINER="kuma-${DB_NAME}"
DB_IMAGE="postgres:13"

SERVICE_DIR="${SERVICE_NAME}"

TOKEN_DIR="./tokens"
NETWORK="kuma-app-network"

SERVICE_TOKEN="${TOKEN_DIR}/token-${SERVICE_NAME}"
DB_TOKEN="${TOKEN_DIR}/token-${DB_NAME}"

SERVICE_DATAPLANE="./kong/kong-dp.yaml"
DB_DATAPLANE="./dataplane.yaml"

mkdir -p "$TOKEN_DIR" "./logs"

# ──────────────── Generate Tokens ────────────────
# echo "🔐 Generating dataplane tokens..."
# kumactl generate dataplane-token \
#   --tag "kuma.io/service=${SERVICE_NAME}" \
#   --valid-for 720h \
#   > "$SERVICE_TOKEN"

# kumactl generate dataplane-token \
#   --tag "kuma.io/service=${DB_NAME}" \
#   --valid-for 720h \
#   > "$DB_TOKEN"


# Remove existing containers if they exist
echo "🧹 Cleaning up existing containers if needed..."

for container in "$CONTAINER_NAME" "$DB_CONTAINER"; do
  if docker ps -a -q -f name="^/${container}$" >/dev/null; then
    echo "🗑️  Removing existing container $container"
    docker rm -f "$container"
  fi
done

KONG_PG_HOST="kong-db"
KONG_PG_DATABASE="kong"
KONG_PG_USER="kong"
KONG_PG_PASSWORD="kong"


docker run -d --name $DB_CONTAINER \
  --hostname "$DB_NAME" \
  --network "$NETWORK" \
  -e "POSTGRES_USER=$KONG_PG_USER" \
  -e "POSTGRES_DB=$KONG_PG_DATABASE" \
  -e "POSTGRES_PASSWORD=$KONG_PG_PASSWORD" \
  --ip "$DB_IP" \
  --volume "$(pwd):/kuma" \
  postgres:13

sleep 5
echo "🗄️  Starting DB container ${DB_CONTAINER}..."

docker run --rm \
  --network "$NETWORK" \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=$KONG_PG_HOST" \
  -e "KONG_PG_DATABASE=$KONG_PG_DATABASE" \
  -e "KONG_PG_USER=$KONG_PG_USER" \
  -e "KONG_PG_PASSWORD=$KONG_PG_PASSWORD" \
  kong:latest kong migrations bootstrap

sleep 5

echo "🚀 Starting service container ${CONTAINER_NAME}..."

docker run -d --name $CONTAINER_NAME \
  --hostname "$SERVICE_NAME" \
  --network "$NETWORK" \
  -e "KONG_DATABASE=postgres" \
  -e "KONG_PG_HOST=$KONG_PG_HOST" \
  -e "KONG_PG_DATABASE=$KONG_PG_DATABASE" \
  -e "KONG_PG_USER=$KONG_PG_USER" \
  -e "KONG_PG_PASSWORD=$KONG_PG_PASSWORD" \
  -e "KONG_PROXY_ACCESS_LOG=/dev/stdout" \
  -e "KONG_ADMIN_ACCESS_LOG=/dev/stdout" \
  -e "KONG_PROXY_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_ERROR_LOG=/dev/stderr" \
  -e "KONG_ADMIN_LISTEN=0.0.0.0:8001, 0.0.0.0:8444 ssl" \
  -e "KONG_PG_SSL=disable" \
  -p 8000:8000 \
  -p 8443:8443 \
  -p 8001:8001 \
  -p 8444:8444 \
  --ip "$SERVICE_IP" \
  --volume "$(pwd):/kuma" \
  kong:latest


# ──────────────── Start Dataplanes ────────────────
echo "⚙️  Starting kuma-dp for DB..."

./start-kuma-dataplane.sh "$DB_NAME" "$DB_IP" "$DB_PORT" "$DB_DATAPLANE" "$DB_TOKEN"

sleep 5

echo "⚙️  Starting kuma-dp for Service..."
./start-kuma-dataplane.sh "$SERVICE_NAME" "$SERVICE_IP" "$SERVICE_PORT" "$SERVICE_DATAPLANE" "$SERVICE_TOKEN"

curl -i -X POST http://localhost:8001/services \
  --data "name=user-service" \
  --data "url=http://user-service:8001"

curl -i -X POST http://localhost:8001/services/user-service/routes \
  --data "paths[]=/users" \
  --data "methods[]=GET" \
  --data "methods[]=POST" \
  --data "methods[]=PUT" \
  --data "methods[]=DELETE" \
  --data "methods[]=OPTIONS" \
  --data "methods[]=PATCH"

echo "✅ ${SERVICE_NAME} and ${DB_NAME} deployed with dataplanes!"
