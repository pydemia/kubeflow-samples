
```bash
kubectl edit -n kubeflow gateways.networking.istio.io kubeflow-gateway
```

```yml
spec:
  selector:
    istio: ingressgateway
  servers:
  - hosts:
    - '*'
    port:
      name: http
      number: 80
      protocol: HTTP
    # Upgrade HTTP to HTTPS
    tls:
      httpsRedirect: true
  - hosts:
    - '*'
    port:
      name: https
      number: 443
      protocol: HTTPS
    tls:
      mode: SIMPLE
      privateKey: /etc/istio/ingressgateway-certs/tls.key
      serverCertificate: /etc/istio/ingressgateway-certs/tls.crt
```