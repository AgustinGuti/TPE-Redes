Project Overview: Migrating a Kuma Service Mesh from Docker to Kubernetes for Canary Deployment

You are migrating a microservice-based e-commerce project from a Docker-based local deployment to Kubernetes to take advantage of Kuma’s Service Mesh capabilities, especially for traffic control and canary deployments. You encountered limitations managing canary traffic routing (e.g., 50/50 balancing) in the Docker environment and now want to resolve them in Kubernetes, where Kuma is better integrated and more powerful.
🎯 Project Objective

To understand, implement, and demonstrate the following:

    Deployment of Kuma as a Service Mesh in Kubernetes.

    Deployment of Kong as an API Gateway integrated with Kuma.

    Coexistence of multiple versions of a microservice in the mesh.

    Implementation of canary release strategies with progressive traffic shifting using Kuma’s TrafficRoute policies.

    Observability and authentication features via Kuma and Kong.

🛠️ Microservices Stack

    Frontend (static, consumes APIs)

    Backend microservices (Java):

        users-service

        sales-service

        products-service → this service will have v1 and v2

⚙️ Migration to Kubernetes

To ensure the system works correctly in Kubernetes, you’ll:

    Use Kuma’s Helm chart or kumactl to deploy the control-plane.

    Deploy each microservice as a Kubernetes Deployment, ensuring they register in Kuma with proper sidecar proxies (kuma-dp).

    Deploy Kong Ingress Controller, configured to use Kuma as a Service Mesh (MeshGateway mode or compatible mode).

    Setup Service and Mesh YAML resources for each microservice version.

🔁 Canary Routing (The Core Need)

You need fine-grained traffic control between two versions of the same service (e.g., products-v1 and products-v2), using Kuma’s TrafficRoute policy.
✅ What You Want to Achieve:

    Register two separate Kubernetes Deployments: products-v1 and products-v2.

    Expose them under the same logical service name in Kuma (e.g., products.kuma.mesh).

    Create a TrafficRoute to initially split traffic 50/50, and later adjust it (e.g., 80/20).

    Observe live traffic distribution, error rates, or delays.

    Be able to roll forward or roll back traffic based on observed metrics.

✍️ Example TrafficRoute YAML for 50/50:

apiVersion: kuma.io/v1alpha1
kind: TrafficRoute
mesh: default
metadata:
  name: products-canary
spec:
  sources:
    - match:
        kuma.io/service: frontend
  destinations:
    - match:
        kuma.io/service: products
  conf:
    split:
      - weight: 50
        destination:
          kuma.io/service: products-v1
      - weight: 50
        destination:
          kuma.io/service: products-v2

This will ensure that when a request goes from the frontend to the products service, Kuma's dataplane proxies split it evenly between v1 and v2.
🧪 Demos to Implement

    Authentication with Kong:

        Protect an endpoint (e.g., /products) using Kong JWT plugin.

        Show token verification without modifying the service logic.

    Tracing & Observability with Kuma:

        Introduce artificial latency in products-v2.

        Use Prometheus + Grafana or Zipkin to show where bottlenecks happen.

    Canary Deployment with Kuma:

        Start with 90/10 (v1/v2), then go to 50/50, and finally 0/100.

        Show live results: how some users get v1 responses and others v2.

🧩 Required Changes for Canary in Kubernetes

    Create two separate Deployments for products-v1 and products-v2, each with its own label or kuma.io/service annotation.

    Ensure both register as different services in Kuma.

    Use a virtual service name (e.g., products) that clients use to connect.

    Define a TrafficRoute as shown above.

    Optionally use MeshGateway to expose services via Kong and apply additional routing rules.

    Validate the behavior using logs, traces, and metrics.

🚀 Goals for Cursor or Any Assistant Tool

When helping with this project, the assistant should:

    Understand you are transitioning from Docker to Kubernetes because TrafficRoute canary logic is not working as expected in Docker.

    Help you generate the correct TrafficRoute definitions.

    Ensure your Kubernetes services and Deployments are compatible with Kuma.

    Provide YAML examples for Kuma’s Mesh, MeshGateway, TrafficPermission, and TrafficRoute.

    Assist you in debugging request distribution across versions.