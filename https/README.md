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
NAMESPACE="kubeflow"
helm install \
  --name nginx-ingress \
  --namespace ${NAMESPACE} \
  stable/nginx-ingress \
  --set rbac.create=true \
  --set controller.publishService.enabled=true
# RBAC disabled
# helm install --name nginx-ingress stable/nginx-ingress
```

```bash
$ kubectl get service nginx-ingress-controller

NAME:   nginx-ingress
LAST DEPLOYED: Sat Dec 19 03:12:01 2020
NAMESPACE: kubeflow
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
```

## Deploy an Ingress Resource

https://github.com/GoogleCloudPlatform/community/blob/master/tutorials/nginx-ingress-gke/ingress-resource.yaml

```bash
# kubectl -n default annotate ingress kubeflow-ingress \
#   kubernetes.io/ingress.class: nginx

kubectl apply -f kubeflow-ingress.yaml
```

