# HTTPS (SSL/TLS Setting)

https://cloud.google.com/community/tutorials/nginx-ingress-gke

## Get helm

```bash
curl -o get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get && \
  chmod +x get_helm.sh && \
  ./get_helm.sh

helm init
```

## Installing Tiller with RBAC enabled

```bash
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account tiller  # --upgrade
```

output:
```ascii
serviceaccount/tiller created
clusterrolebinding.rbac.authorization.k8s.io/tiller-cluster-rule created
$HELM_HOME has been configured at /home/pydemia/.helm.

Tiller (the Helm server-side component) has been updated to gcr.io/kubernetes-helm/tiller:v2.16.7 .
```

## Deploy `nginx-ingress-controller` with RBAC enabled

```bash
helm repo add stable https://charts.helm.sh/stable

# NAMESPACE="kubeflow"
NAMESPACE="istio-system"
helm install \
  --name nginx-ingress \
  --namespace ${NAMESPACE} \
  stable/nginx-ingress \
  --set rbac.create=true \
  --set controller.publishService.enabled=true \
  --set ingressShim.defaultIssuerName=letsencrypt-prod
  # --set ingressShim.defaultIssuerKind=ClusterIssuer 
# RBAC disabled
# helm install --name nginx-ingress stable/nginx-ingress
# helm delete --purge nginx-ingress
```

```bash
$ kubectl -n ${NAMESPACE} get service nginx-ingress-controller

NAME:   nginx-ingress
LAST DEPLOYED: Sat Dec 19 03:12:01 2020
NAMESPACE: istio-system
STATUS: DEPLOYED

RESOURCES:
==> v1/ClusterRole
NAME           AGE
nginx-ingress  2s

==> v1/ClusterRoleBinding
NAME           AGE
nginx-ingress  2s

==> v1/Deployment
NAME                           READY  UP-TO-DATE  AVAILABLE  AGE
nginx-ingress-controller       0/1    0           0          1s
nginx-ingress-default-backend  0/1    0           0          1s

==> v1/Pod(related)

==> v1/Role
NAME           AGE
nginx-ingress  2s

==> v1/RoleBinding
NAME           AGE
nginx-ingress  2s

==> v1/Service
NAME                           TYPE          CLUSTER-IP     EXTERNAL-IP  PORT(S)                     AGE
nginx-ingress-controller       LoadBalancer  172.19.10.121  <pending>    80:30045/TCP,443:30577/TCP  1s
nginx-ingress-default-backend  ClusterIP     172.19.21.47   <none>       80/TCP                      1s

==> v1/ServiceAccount
NAME                   SECRETS  AGE
nginx-ingress          1        2s
nginx-ingress-backend  1        2s


NOTES:
The nginx-ingress controller has been installed.
It may take a few minutes for the LoadBalancer IP to be available.
You can watch the status by running 'kubectl --namespace kubeflow get services -o wide -w nginx-ingress-controller'

An example Ingress that makes use of the controller:

  apiVersion: extensions/v1beta1
  kind: Ingress
  metadata:
    annotations:
      kubernetes.io/ingress.class: nginx
    name: example
    namespace: foo
  spec:
    rules:
      - host: www.example.com
        http:
          paths:
            - backend:
                serviceName: exampleService
                servicePort: 80
              path: /
    # This section is only required if TLS is to be enabled for the Ingress
    tls:
        - hosts:
            - www.example.com
          secretName: example-tls

If TLS is enabled for the Ingress, a Secret containing the certificate and key must also be provided:

  apiVersion: v1
  kind: Secret
  metadata:
    name: example-tls
    namespace: foo
  data:
    tls.crt: <base64 encoded cert>
    tls.key: <base64 encoded key>
  type: kubernetes.io/tls
```

## Set `Let's encrypt` `ClusterIssuer` in `cert-manager`

```yml
USER_EMAIL="pydemia@gmail.com"

cat << EOF | kubectl apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${USER_EMAIL}
    privateKeySecretRef:
      name: letsencrypt
    http01: {}
EOF

## Let's Encrypt

```yml
```yml
USER_EMAIL="pydemia@gmail.com"
DOMAIN="kubeflow.pydemia.org"

cat << EOF | kubectl apply -f -
apiVersion: certmanager.k8s.io/v1alpha1
kind: ClusterIssuer
metadata:
  name: letsencrypt
  namespace: cert-manager
spec:
  acme:
    email: pydemia@gmail.com
    server: https://acme-v02.api.letsencrypt.org/directory
    preferredChain: "ISRG Root X1"
    privateKeySecretRef:
      name: letsencrypt
    http01: {}
EOF
```


```yml
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: nginx-tls
  namespace: YOUR NAMESPACE
spec:
  secretName: nginx-tls
  issuerRef:
    name: letsencrypt
    kind: ClusterIssuer
  dnsNames:
    - "*.pydemia.org"
  acme:
    config:
      - dns01:
          provider: route53
        domains:
          - "*.pydemia.org"
```

```bash
kubectl apply -f issuers.yaml
# kubectl apply -f clusterissuers.yaml
# kubectl apply -f certificate-http-nginx.yaml

kubectl describe -f issuers.yaml
# kubectl describe -f clusterissuers.yaml
# kubectl describe -f certificate-http-nginx.yaml
```
## Deploy an Ingress Resource

https://github.com/GoogleCloudPlatform/community/blob/master/tutorials/nginx-ingress-gke/ingress-resource.yaml

```yml
...
metadata:
  name: kubeflow-ingress
  namespace: kubeflow
  annotations:
    # cert-manager.io/issuer: letsencrypt-prod
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
...
spec:
  tls:
  - hosts:
    - kubeflow.pydemia.org
    secretName: nginx-tls
...
```


```bash
# kubectl -n default annotate ingress kubeflow-ingress \
#   kubernetes.io/ingress.class: nginx

kubectl apply -f kubeflow-ingress.yaml
kubectl describe -f kubeflow-ingress.yaml
```


Then, Automatically create `certificates.cert-manager.io` named `nginx-tls-prod` or `nginx-tls-staging`.
You should edit this as the following:



```bash
kubectl -n kubeflow edit certificates.cert-manager.io nginx-tls-prod
```

From: 

```bash
spec:
  dnsNames:
  - kf-dev.pydemia.org
  issuerRef:
    group: cert-manager.io
    kind: Issuer
    name: letsencrypt-prod
  secretName: nginx-tls-prod
```

To:

```bash
spec:
  dnsNames:
  - kf-dev.pydemia.org
  issuerRef:
    group: cert-manager.io
    kind: Issuer
    name: letsencrypt-prod
  secretName: nginx-tls-prod
  acme:
    config:
      - http01:
        ingressClass: nginx
        domains:
        - kf-dev.pydemia.org
```

```yml
kubectl -n kubeflow patch certificates.cert-manager.io nginx-tls-staging \
  --type merge \
  --patch "spec:
  dnsNames:
  - kf-dev.pydemia.org
  issuerRef:
    group: cert-manager.io
    kind: Issuer
    name: letsencrypt-staging
  secretName: nginx-tls-staging
  acme:
    config:
      - http01:
        ingressClass: nginx
        domains:
        - kf-dev.pydemia.org
"
```

```yml
kubectl -n kubeflow patch certificates.cert-manager.io nginx-tls-prod \
  --type merge \
  --patch "spec:
  dnsNames:
  - kf.pydemia.org
  issuerRef:
    group: cert-manager.io
    kind: Issuer
    name: letsencrypt-prod
  secretName: nginx-tls-prod
  acme:
    config:
      - http01:
        ingressClass: nginx
        domains:
        - kf.pydemia.org
"
```

Troubleshooting:

Waiting:

```bash
kubectl -n kubeflow describe certificates.cert-manager.io nginx-tls
kubectl -n kubeflow describe certificaterequests.cert-manager.io nginx-tls-prod-4287005911
```

Waiting: 

```ascii
Spec:
  Dns Names:
    kf.pydemia.org
  Issuer Ref:
    Group:      cert-manager.io
    Kind:       Issuer
    Name:       letsencrypt-prod
  Secret Name:  nginx-tls-prod
Status:
  Conditions:
    Last Transition Time:  2020-12-22T09:06:42Z
    Message:               Waiting for CertificateRequest "nginx-tls-prod-4287005911" to complete
    Reason:                InProgress
    Status:                False
    Type:                  Ready
Events:
  Type    Reason     Age   From          Message
  ----    ------     ----  ----          -------
  Normal  Requested  57s   cert-manager  Created new CertificateRequest resource "nginx-tls-prod-4287005911"
```

Pending:

```ascii
Status:
  Conditions:
    Last Transition Time:  2020-12-22T09:06:42Z
    Message:               Waiting on certificate issuance from order kubeflow/nginx-tls-prod-4287005911-2607685879: "pending"
    Reason:                Pending
    Status:                False
    Type:                  Ready
Events:
  Type    Reason        Age    From          Message
  ----    ------        ----   ----          -------
  Normal  OrderCreated  2m44s  cert-manager  Created Order resource kubeflow/nginx-tls-prod-4287005911-2607685879
```

```bash
# <  v0.11: orders.acme.cert-manager.io
# >= v0.11: orders.certmanager.k8s.io  
kubectl -n kubeflow describe orders.acme.cert-manager.io nginx-tls-prod-4287005911-2607685879

kubectl -n kubeflow delete certificates.cert-manager.io nginx-tls-prod
kubectl -n kubeflow delete certificates.cert-manager.io nginx-tls-staging
kubectl -n kubeflow delete certificaterequests.cert-manager.io nginx-tls-prod-4287005911
kubectl -n kubeflow delete orders.acme.cert-manager.io nginx-tls-prod-4287005911-2607685879
```


kubectl delete -f letsencrypt-nginx.yaml
kubectl -n kubeflow delete certificates.cert-manager.io nginx-tls-prod
kubectl -n kubeflow delete certificates.cert-manager.io nginx-tls-staging


---

```bash
kubectl apply -f letsencrypt-nginx.yaml
kubectl -n kubeflow describe certificates.cert-manager.io nginx-tls
kubectl -n kubeflow describe certificaterequests.cert-manager.io nginx-tls-prod-4287005911
kubectl -n kubeflow describe orders.acme.cert-manager.io nginx-tls-prod-4287005911-2607685879
```

---
Activate Istio Authorization

```bash
kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ClusterRbacConfig
metadata:
  name: default
spec:
  mode: 'ON_WITH_INCLUSION'
  inclusion:
    namespaces: ["default"]
EOF
```

```bash
kubectl apply -f - <<EOF
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRole
metadata:
  name: centraldashboard
  namespace: kubeflow
spec:
  rules:
  - services:
    - centraldashboard.kubeflow.svc.cluster.local
  # - services: ["*"]
  #   methods: ["GET"]
  #   constraints:
  #   - key: "destination.labels[app]"
  #     values: ["productpage", "details", "reviews", "ratings"]
---
apiVersion: "rbac.istio.io/v1alpha1"
kind: ServiceRoleBinding
metadata:
  name: bind-centraldashboard
  namespace: kubeflow
spec:
  subjects:
    - user: "*"
  # - properties:
  #     source.namespace: istio-system
  roleRef:
    kind: ServiceRole
    name: centraldashboard
EOF
```

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: centraldashboard-auth
  namespace: kubeflow
spec:
  selector:
    matchLabels:
      app: centraldashboard
  rules:
  - to:
    - operation:
        methods: ["GET", "POST"]
EOF
```


https://istio.io/latest/docs/tasks/security/authorization/authz-http/

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: centraldashboard-auth
  namespace: kubeflow
spec:
  selector:
    matchLabels:
      app: centraldashboard
  rules:
  - to:
    - operation:
        methods: ["GET", "POST"]
EOF
```