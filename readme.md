# Docker Compose command

docker compose -f docker-compose.yml \
               -f docker-compose.init.yml \
               -f docker-compose.user.yml \
               -f docker-compose.product.yml \
               -f docker-compose.product-2.yml \
               -f docker-compose.sales.yml \
               -f docker-compose.kong.yml \
               -f docker-compose.kong-config.yml \
               up --build


# Requisitos

snap install -y yq


## Setting up docker network
docker network create \
  --subnet 192.168.0.0/24 \
  --gateway 192.168.0.254 \
  kuma-app-network

## Start the control plane
docker run \
  --detach \
  --name kuma-demo-control-plane \
  --hostname control-plane \
  --network kuma-app-network \
  --ip 192.168.0.1 \
  --publish 25681:5681 \
  --volume "./:/control_plane" \
  kumahq/kuma-cp:2.10.1 run


## Retrieve the admin token

Run the following command to get the admin token from the control plane:

export KUMA_ADMIN_TOKEN="$( 
  docker exec --tty --interactive kuma-demo-control-plane \
    wget --quiet --output-document - \
    http://127.0.0.1:5681/global-secrets/admin-user-token \
    | jq --raw-output .data \
    | base64 --decode
)"

Use the retrieved token to link kumactl to the control plane:

kumactl config control-planes add \
  --name kuma-app-network \
  --address http://127.0.0.1:25681 \
  --auth-type tokens \
  --auth-conf "token=$KUMA_ADMIN_TOKEN" \
  --skip-verify

## Configure the default mesh
Set the default mesh to use MeshServices in Exclusive mode. MeshServices are explicit resources that represent destinations for traffic in the mesh. They define which Dataplanes serve the traffic, as well as the available ports, IPs, and hostnames. This configuration ensures a clearer and more precise way to manage services and traffic routing in the mesh.

echo 'type: Mesh
name: default
meshServices:
  mode: Exclusive' | kumactl apply -f -


# Set up services

## Generate a data plane token

kumactl generate dataplane-token \
  --tag kuma.io/service=user-service \
  --valid-for 720h \
  > "./tokens/token-user-service"


cd ../user-service
## Build the user service image

docker build \
  --tag user-service-img \
  --file Dockerfile \
  .

## Start the container

docker run -d \
  --name user-db \
  --network kuma-app-network \
  -e POSTGRES_USER=myuser \
  -e POSTGRES_PASSWORD=mypassword \
  -e POSTGRES_DB=userdata \
  postgres:15

docker run \
  --detach \
  --name kuma-user-service \
  --hostname user-service \
  --network kuma-app-network \
  --ip 192.168.0.3 \
  -e DATABASE_URL=postgresql://myuser:mypassword@user-db:5432/userdata \
  --volume "./:/kuma" \
  user-service-img:latest

## Configure the data plane
Install tools and create data plane proxy user

docker exec --tty --interactive --privileged kuma-user-service bash

### install necessary packages
apt-get update && \
  apt-get install --yes curl iptables
      
### download and install Kuma
curl --location https://kuma.io/installer.sh | VERSION="2.10.1" sh -
      
### move Kuma binaries to /usr/local/bin/ for global availability
mv kuma-2.10.1/bin/* /usr/local/bin/
      
### create a dedicated user for the data plane proxy
useradd --uid 5678 --user-group kuma-data-plane-proxy

## Start the data plane proxy

runuser --user kuma-data-plane-proxy -- \
  /usr/local/bin/kuma-dp run \
    --cp-address https://control-plane:5678 \
    --dataplane-token-file /kuma/tokens/token-user-service \
    --dataplane-file /kuma/dataplane.yaml \
    --dataplane-var name=user-service \
    --dataplane-var address=192.168.0.3 \
    --dataplane-var port=8001 \
    > /kuma/logs/logs-data-plane-proxy-user-service.log 2>&1 &

## Install the transparent proxy

kumactl install transparent-proxy \
  --config-file /kuma/config-transparent-proxy.yaml \
  > /kuma/logs/logs-transparent-proxy-install-user-service.log 2>&1












minikube start



helm repo add kuma https://kumahq.github.io/charts
helm repo add kong https://charts.konghq.com

helm repo update
helm install --create-namespace --namespace kuma-system kuma kuma/kuma

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml --namespace kuma-system
kubectl apply -f k8s/gateway.yaml

helm install kong kong/ingress -n kuma-system --create-namespace 

<!-- 
export PROXY_IP=$(kubectl get svc --namespace kuma-system kong-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP 
-->

minikube image load product-service:v1
minikube image load sales-service:v1
minikube image load user-service:v1

kubectl label namespace kuma-system kuma.io/sidecar-injection=enabled

helm install app-prod ./services-chart/ --namespace kuma-system
<!--
helm upgrade app-prod ./services-chart/ --namespace kuma-system
-->

kubectl apply -f k8s/kong/

<!-- 
curl -i $PROXY_IP/products 
kubectl get ing -n kuma-system
-->

kubectl apply -f kuma/security-mesh.yaml


helm upgrade kong kong/kong -n kuma-system -f k8s/kong-values.yaml


kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681

kubectl port-forward service/kong-gateway-kong-admin -n kuma-system 8080:8444

