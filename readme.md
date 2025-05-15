## Setting up docker network
docker network create \
  --subnet 192.168.0.0/24 \
  --gateway 192.168.0.254 \
  kuma-demo

## Start the control plane
docker run \
  --detach \
  --name kuma-demo-control-plane \
  --hostname control-plane \
  --network kuma-demo \
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
  --name kuma-demo \
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

## Start the container

docker run \
  --detach \
  --name kuma-user-service \
  --hostname user-service \
  --network kuma-demo \
  --ip 192.168.0.3 \
  --volume "./:/demo" \
  user-service-image:latest
