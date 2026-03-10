cat > create_gateway_manifests.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Creating gatewayclass.yaml..."
cat > gatewayclass.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: GatewayClass
metadata:
  name: envoy
spec:
  controllerName: gateway.envoyproxy.io/gatewayclass-controller
  parametersRef:
    group: gateway.envoyproxy.io
    kind: EnvoyProxy
    name: proxy
    namespace: envoy-gateway-system
YAML

echo "Creating gateway.yaml..."
cat > gateway.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: web-gateway
  namespace: default
spec:
  gatewayClassName: envoy
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
YAML

echo "Creating envoyproxy.yaml..."
cat > envoyproxy.yaml <<'YAML'
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: EnvoyProxy
metadata:
  name: proxy
  namespace: envoy-gateway-system
spec:
  provider:
    type: Kubernetes
    kubernetes:
      envoyService:
        type: LoadBalancer
        loadBalancerIP: "x.x.x.x"
        externalTrafficPolicy: Cluster
YAML

echo "Creating httproute.yaml..."
cat > httproute.yaml <<'YAML'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: web-httproute
spec:
  parentRefs:
    - name: web-gateway
  rules:
    - backendRefs:
        - group: ""
          kind: Service
          name: web-svc
          port: 80
          weight: 1
      matches:
        - path:
            type: PathPrefix
            value: /
YAML

echo "Applying manifests in order..."
kubectl apply --validate=false -f gatewayclass.yaml
kubectl apply --validate=false -f gateway.yaml
kubectl apply --validate=false -f envoyproxy.yaml
kubectl apply --validate=false -f httproute.yaml

echo "Done."
EOF
