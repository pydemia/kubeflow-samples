
```bash
kubectl patch hpa -n istio-system istio-galley -p '{"spec":{"minReplicas": 2}}' --type=merge
kubectl patch hpa -n istio-system istio-ingressgateway -p '{"spec":{"minReplicas": 2}}' --type=merge
kubectl patch hpa -n istio-system istio-nodeagent -p '{"spec":{"minReplicas": 2}}' --type=merge
kubectl patch hpa -n istio-system istio-pilot -p '{"spec":{"minReplicas": 2}}' --type=merge
kubectl patch hpa -n istio-system istio-sidecar-injector -p '{"spec":{"minReplicas": 2}}' --type=merge
```