
minikube start

helm repo add kuma https://kumahq.github.io/charts
helm repo add kong https://charts.konghq.com

helm repo update
helm install --create-namespace --namespace kuma-system kuma kuma/kuma

kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml --namespace kuma-system

helm install kong kong/ingress -n kuma-system --create-namespace 

<!-- 
export PROXY_IP=$(kubectl get svc --namespace kuma-system kong-gateway-proxy -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $PROXY_IP 
-->

docker build -t product-service:v1 ../product-service
docker build -t product-service:v2 ../product-service-2
docker build -t sales-service:v1 ../sales-service
docker build -t user-service:v1 ../user-service

minikube image load product-service:v1
minikube image load product-service:v2
minikube image load sales-service:v1
minikube image load user-service:v1

kubectl label namespace kuma-system kuma.io/sidecar-injection=enabled

helm install app-prod ./services-chart/ --namespace kuma-system

<!--
helm upgrade app-prod ./services-chart/ --namespace kuma-system
-->

kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/kong/

<!-- 
curl -i $PROXY_IP/products 
kubectl get ing -n kuma-system
-->

kubectl apply -f kuma/mesh.yaml
kubectl apply -f kuma/traffic-permissions-gateway.yaml
kubectl apply -f kuma/traffic-permissions-services.yaml

kubectl apply -f kuma/traffic-permissions-all.yaml



helm upgrade kong kong/kong -n kuma-system -f k8s/kong-values.yaml


kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681

kubectl port-forward service/kong-gateway-kong-admin -n kuma-system 8080:8444

