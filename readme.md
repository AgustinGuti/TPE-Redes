# Microservicios de E-Commerce con Kuma Service Mesh

Este proyecto demuestra una arquitectura de microservicios para una plataforma de comercio electrónico utilizando:
- Kuma service mesh para descubrimiento de servicios y gestión de tráfico
- Kong API Gateway para gestión de API y autenticación
- Kubernetes (a través de Minikube) para orquestación de contenedores

El sistema consta de tres servicios principales: Usuario, Producto y Ventas, cada uno con su propia base de datos.

## Visión general de la arquitectura

| Servicio | Propósito | Endpoints |
|----------|-----------|-----------|
| Servicio de Usuario | Autenticación y gestión de usuarios | `/users`, `/users/login` |
| Servicio de Producto | Catálogo de productos e inventario | `/products` |
| Servicio de Ventas | Procesamiento de pedidos | `/sales` |

# Inicializar Minikube con Docker y Kuma

## Instrucciones de configuración

### 1. Prerequisitos
- [Minikube](https://minikube.sigs.k8s.io/docs/start/) v1.28+
- [Docker](https://docs.docker.com/get-docker/) v28+
- [Helm](https://helm.sh/docs/intro/install/) v3.8+
- [Kuma](https://kuma.io/docs/2.10.x/introduction/install/) v1.10+
- [kubectl](https://kubernetes.io/docs/tasks/tools/) v1.25+

### 2. Construcción y configuración del entorno
### Ubicarse en el directorio de ejecución
```bash
cd kuma
```

### Creación de imagenes de Docker
```bash
docker build -t product-service:v1 ../product-service
docker build -t product-service:v2 ../product-service-2
docker build -t sales-service:v1 ../sales-service
docker build -t user-service:v1 ../user-service
```

### Creación de la red Docker
```bash
docker network create --driver=bridge --subnet=10.0.0.0/24  minikube-net
```

### Iniciar Minikube con la red Docker y configuración de pod CIDR
```bash
MINIKUBE_DOCKER_NETWORK=minikube-net minikube start --driver=docker --extra-config=kubelet.pod-cidr=192.168.0.0/24
```

### Cargar las imágenes de Docker en Minikube
```bash
minikube image load product-service:v1
minikube image load product-service:v2
minikube image load sales-service:v1
minikube image load user-service:v1
```

### Instalar Helm y configurar repositorios
```bash
helm repo add kuma https://kumahq.github.io/charts
helm repo add kong https://charts.konghq.com

helm repo update
```

## Kuma

### Instalar Kuma
```bash
helm install --create-namespace --namespace kuma-system kuma kuma/kuma
kubectl wait --namespace kuma-system --for=condition=available deployment/kuma-control-plane --timeout=600s
```

### Habilitar inyección de sidecar en el namespace `ecommerce`
```bash
kubectl create namespace ecommerce
kubectl label namespace ecommerce kuma.io/sidecar-injection=enabled
```


### Configurar mTLS y permisos de tráfico en Kuma
```bash
kubectl apply -f kuma/
```

### Deployar los servicios
```bash
helm install app-prod ./services-chart/ --namespace ecommerce
```

## Kong Gateway

### Instalar Kong Gateway y Gateway API
```bash
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.1.0/standard-install.yaml --namespace ecommerce

helm install kong kong/ingress -n ecommerce --create-namespace
```

### Configurar el proxy de Kong
```bash
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/kong/

helm upgrade kong kong/kong -n ecommerce -f k8s/kong-values.yaml
```

## Instalar observabilidad
```bash
kumactl install observability | kubectl apply -f -
```

### Abrir túnel de Minikube para acceso a servicios (En otra terminal)
```bash
minikube tunnel
```

## Esperar a que todos los pods estén listos
```bash
kubectl wait --for=condition=ready --timeout=600s --namespace=ecommerce pods --all
```

### Abrir puertos para acceder a la observabilidad (En diferentes terminales)
```bash
kubectl port-forward svc/grafana 3000:80 -n mesh-observability
kubectl port-forward svc/jaeger-query 16686:80 -n mesh-observability
```
