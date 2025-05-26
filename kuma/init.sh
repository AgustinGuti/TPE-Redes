#!/bin/sh
set -e

echo "Waiting for control plane..."

# Get admin token
echo "Retrieving admin token..."
KUMA_ADMIN_TOKEN=$(cat /tokens/admin-token)

echo "Admin token retrieved: $KUMA_ADMIN_TOKEN"

echo "Configuring kumactl..."
kumactl config control-planes add \
  --name kuma-app-network \
  --address http://control-plane:5681 \
  --auth-type tokens \
  --auth-conf "token=$KUMA_ADMIN_TOKEN" \
  --overwrite \
  --skip-verify

echo "Setting up default mesh config..."
kumactl apply -f - <<EOF
type: Mesh
name: default
meshServices:
  mode: Exclusive
EOF

echo "Generating tokens..."


mkdir -p /tokens
kumactl generate dataplane-token --tag kuma.io/service=user-service --valid-for 720h  > /tokens/token-user-service
kumactl generate dataplane-token --tag kuma.io/service=user-service-db --valid-for 720h  > /tokens/token-user-service-db
kumactl generate dataplane-token --tag kuma.io/service=product-service --valid-for 720h  > /tokens/token-product-service
kumactl generate dataplane-token --tag kuma.io/service=product-service-db --valid-for 720h  > /tokens/token-product-service-db
kumactl generate dataplane-token --tag kuma.io/service=kong --valid-for 720h  > /tokens/token-kong
kumactl generate dataplane-token --tag kuma.io/service=kong-db --valid-for 720h > /tokens/token-kong-db

echo "Init complete"
