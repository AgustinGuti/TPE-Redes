#!/bin/bash

# Ensure all scripts are executable
chmod +x setup-kuma-control-plane.sh
chmod +x start-kuma-service.sh
chmod +x start-kuma-dataplane.sh

# Step 1: Start control plane
./setup-kuma-control-plane.sh

# Step 2: Loop through each service in services.yaml
SERVICE_FILE="./service-config.yaml"

SERVICES=$(yq eval '.services | length' "$SERVICE_FILE")
echo "🔧 Setting up $SERVICES service(s)..."

for i in $(seq 0 $((SERVICES - 1))); do
  NAME=$(yq eval ".services[$i].name" "$SERVICE_FILE")
  SVC_IP=$(yq eval ".services[$i].service-ip" "$SERVICE_FILE")
  SVC_PORT=$(yq eval ".services[$i].service-port" "$SERVICE_FILE")
  DB_IP=$(yq eval ".services[$i].database-ip" "$SERVICE_FILE")
  DB_PORT=$(yq eval ".services[$i].database-port" "$SERVICE_FILE")

  echo "🚀 Setting up $NAME..."
  ./start-kuma-service.sh "$NAME" "$SVC_IP" "$SVC_PORT" "$DB_IP" "$DB_PORT"
done

echo "✅ All services configured!"
