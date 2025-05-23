#!/bin/sh
set -e

mkdir -p certs
kumactl generate tls-certificate --type=server --hostname=control-plane --cert-file=certs/server.crt --key-file=certs/server.key
chmod 644 certs/server.crt certs/server.key

# Arranca el control plane en segundo plano
kuma-cp run &

# Espera a que el control plane esté listo (chequeo de salud)
echo "Waiting for control plane to be healthy..."
until curl -f http://localhost:5681/; do
  echo "Waiting..."
  sleep 2
done

# Obtiene el token admin
echo "Retrieving admin token..."
ADMIN_TOKEN=$(wget --quiet --output-document - http://localhost:5681/global-secrets/admin-user-token | jq -r .data | base64 -d)
echo "Admin token: $ADMIN_TOKEN"


# (Opcional) Guarda el token en un archivo compartido para que otros servicios lo usen
echo $ADMIN_TOKEN > /tokens/admin-token

# Mantiene el proceso principal en primer plano para que el container no termine
wait
