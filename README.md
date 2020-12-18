# kubeflow-samples

Kubeflow & Kfserving Codes.


* [Setup `kubectl`](#setup-kubectl)
  * [Install `kubectl`](#install-kubectl)
  * [Auto-completion](#auto-completion)
  * [(Optional) Install `k9s`](#optional-install-k9s)
* [Setup a k8s Cluster](#setup-a-k8s-cluster)
*

## Setup `kubectl`

### Install `kubectl`

```bash
k_os_type="linux"  # "darwin" for mac
kctl_version="$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)"  # v1.20.0
curl -LO https://storage.googleapis.com/kubernetes-release/release/"${kctl_version}"/bin/"${k_os_type}"/amd64/kubectl && \
  chmod +x ./kubectl && \
  sudo mv ./kubectl /usr/local/bin/kubectl && \
  echo "\nInstalled in: $(which kubectl)"
  kubectl version --client
```

### Auto-completion

* Bash

```bash
pkg_mgr="apt"  # {"apt", "yum"}
sudo $pkg_mgr install -y bash-completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
```

* Zsh

```zsh
echo 'source <(kubectl completion zsh)' >>~/.zshrc
```

* Zsh with `oh-my-zsh`

in `~/.zshrc`:

```zsh
plugins=(git ... kubectl)
```

### Install `kustomize`

* Linux

```bash
curl -s "https://raw.githubusercontent.com/\
kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash && \
sudo mv ./kustomize /usr/local/bin/
```

* Mac

```bash
brew install kustomize
```

### (Optional) Install `k9s`

https://github.com/derailed/k9s/releases

```bash
k9s_version="v0.24.2"
k_os_type="linux"  # "darwin" for mac
curl -L https://github.com/derailed/k9s/releases/download/"${k9s_version}"/k9s_"$(echo "${k_os_type}" |sed 's/./\u&/')"_x86_64.tar.gz -o k9s.tar.gz && \
  mkdir -p ./k9s && \
  tar -zxf k9s.tar.gz -C ./k9s && \
  sudo mv ./k9s/k9s /usr/local/bin/ && \
  rm -rf ./k9s ./k9s.tar.gz && \
  echo "\nInstalled in: $(which k9s)"
```


## (Optional) Get helm

```bash
curl -o get_helm.sh https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get
chmod +x get_helm.sh
./get_helm.sh
```

---

## Setup a k8s Cluster

### GKE

[Kubeflow Requirements](https://www.kubeflow.org/docs/started/k8s/overview/#minimum-system-requirements)

set proper parameters on this script regarding the above link:
`./install-cluster/create-gke-for-kubeflow.sh`

and run:

```bash
$ ./install-cluster/create-gke-for-kubeflow.sh

Enter cluster-name [kubeflow-alpha]: 
WARNING: Warning: basic authentication is deprecated, and will be removed in GKE control plane versions 1.19 and newer. For a list of recommended authentication methods, see: https://cloud.google.com/kubernetes-engine/docs/how-to/api-server-authentication
WARNING: Modifications on the boot disks of node VMs do not persist across node recreations. Nodes are recreated during manual-upgrade, auto-upgrade, auto-repair, and auto-scaling. To preserve modifications across node recreation, use a DaemonSet.
WARNING: The Pod address range limits the maximum size of the cluster. Please refer to https://cloud.google.com/kubernetes-engine/docs/how-to/flexible-pod-cidr to learn how to optimize IP address allocation.
This will enable the autorepair feature for nodes. Please see https://cloud.google.com/kubernetes-engine/docs/node-auto-repair for more information on node autorepairs.
Creating cluster kubeflow-alpha in us-central1... Cluster is being health-checked (master is healthy)...done.                                                                                                    
Created [https://container.googleapis.com/v1beta1/projects/ds-ai-platform/zones/us-central1/clusters/kubeflow-alpha].
To inspect the contents of your cluster, go to: https://console.cloud.google.com/kubernetes/workload_/gcloud/us-central1/kubeflow-alpha?project=ds-ai-platform
kubeconfig entry generated for kubeflow-alpha.
NAME            LOCATION     MASTER_VERSION    MASTER_IP    MACHINE_TYPE   NODE_VERSION      NUM_NODES  STATUS
kubeflow-alpha  us-central1  1.17.12-gke.1504  34.72.90.36  n1-standard-8  1.17.12-gke.1504  3          RUNNING
```

---
## Install `kubeflow`

[Install `kubeflow` with `dex`](https://www.kubeflow.org/docs/started/k8s/kfctl-istio-dex/)

:warning: be careful of [this prerequisites](https://www.kubeflow.org/docs/started/k8s/kfctl-istio-dex/#before-you-start)

### Download `kfctl`

https://github.com/kubeflow/kfctl/releases

* Mac
```bash
curl -L https://github.com/kubeflow/kfctl/releases/download/v1.2.0/kfctl_v1.2.0-0-gbc038f9_darwin.tar.gz -o kfctl.tar.gz && \
  tar -zxf kfctl_v1.2.0-0-gbc038f9_darwin.tar.gz && \
  sudo mv ./kfctl /usr/local/bin/ && \
  rm kfctl.tar.gz && \
  echo "\nInstalled in: $(which kfctl)"
```

* Linux
```bash
curl -L https://github.com/kubeflow/kfctl/releases/download/v1.2.0/kfctl_v1.2.0-0-gbc038f9_linux.tar.gz -o kfctl.tar.gz && \
  tar -zxf kfctl.tar.gz && \
  sudo mv ./kfctl /usr/local/bin/ && \
  rm kfctl.tar.gz && \
  echo "\nInstalled in: $(which kfctl)"
```

### Set environment variables

```bash
# Set the following kfctl configuration file:
# https://github.com/kubeflow/manifests/tree/v1.2.0/kfdef
export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.2-branch/kfdef/kfctl_istio_dex.v1.2.0.yaml"
# export CONFIG_URI="https://raw.githubusercontent.com/kubeflow/manifests/v1.2.0/kfdef/kfctl_istio_dex.v1.0.2.yaml"

# Set KF_NAME to the name of your Kubeflow deployment. You also use this
# value as directory name when creating your configuration directory.
# For example, your deployment name can be 'my-kubeflow' or 'kf-test'.
export KF_NAME="kubeflow-alpha"

# Set the path to the base directory where you want to store one or more 
# Kubeflow deployments. For example, /opt.
# Then set the Kubeflow application directory for this deployment.

# symlink NOT WORKING!!
export BASE_DIR="$(pwd)"/install-cluster/kubeflow-1.2
export KF_DIR=${BASE_DIR}/${KF_NAME}

mkdir -p ${KF_DIR}
# cd ${KF_DIR}

# Download the config file and change the default login credentials.
curl -L $CONFIG_URI -o ${KF_DIR}/kfctl_istio_dex.yaml
export CONFIG_FILE=${KF_DIR}/kfctl_istio_dex.yaml

# Credentials for the default user are admin@kubeflow.org:12341234
# To change them, please edit the dex-auth application parameters
# inside the KfDef file.
vim $CONFIG_FILE
```

Finally,

```bash
kfctl apply -V -f ${CONFIG_FILE} > kubeflow-1.2-install.log 2>&1
```

or build & configure it before deploying:

```bash
export BASE_DIR="$(pwd)"/install-cluster/kubeflow-1.2-build
export KF_DIR=${BASE_DIR}/${KF_NAME}
mkdir -p ${KF_DIR}
cd ${KF_DIR}
kfctl build -V -f ${CONFIG_URI} > kubeflow-1.2-build.log 2>&1

export CONFIG_FILE=${KF_DIR}/kfctl_istio_dex.yaml
kfctl apply -V -f ${CONFIG_FILE}
```

### Change the basic authentication

```bash
# Download the dex config
kubectl get configmap dex -n auth -o jsonpath='{.data.config\.yaml}' > dex-config.yaml

# Edit the dex config with extra users.
# The password must be hashed with bcrypt with an at least 10 difficulty level.
# You can use an online tool like: https://passwordhashing.com/BCrypt

# After editing the config, update the ConfigMap
kubectl create configmap dex --from-file=config.yaml=dex-config.yaml -n auth --dry-run -oyaml | kubectl apply -f -

# Restart Dex to pick up the changes in the ConfigMap
kubectl rollout restart deployment dex -n auth
```

---

### Expose with HTTPS

```bash
kubectl -n kubeflow get gw kubeflow-gateway -o yaml

kubectl edit -n kubeflow gateways.networking.istio.io kubeflow-gateway
```

From:

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
```

To:

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

```bash
kubectl -n kubeflow patch gw kubeflow-gateway \
  --type merge \
  --patch "spec:
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
"
```

### Expose with a LoadBalancer

```bash
kubectl -n istio-system patch svc istio-ingressgateway -p '{"spec": {"type": "LoadBalancer"}}'
kubectl -n istio-system get svc istio-ingressgateway -w -o jsonpath='{.status.loadBalancer.ingress[0]}'
```

### Create the Certificate with cert-manager

After set `LoadBalancer`:

```yml

lb_ip=$(kubectl -n istio-system get svc istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1alpha2
kind: Certificate
metadata:
  name: istio-ingressgateway-certs
  namespace: istio-system
spec:
  commonName: istio-ingressgateway.istio-system.svc
  # Use ipAddresses if your LoadBalancer issues an IP
  ipAddresses:
  - ${lb_ip}
  # Use dnsNames if your LoadBalancer issues a hostname (eg on AWS)
  dnsNames:
  - kubeflow.pydemia.org
  isCA: true
  issuerRef:
    kind: ClusterIssuer
    name: kubeflow-self-signing-issuer
  secretName: istio-ingressgateway-certs
EOF
```

---

https://github.com/kubeflow/kubeflow/issues/4961#issuecomment-614718805

> The `kfctl_istio` config uses `Istio 1.6.1` manifests.
> The `kfctl_istio_dex` config uses `Istio 1.3.1` manifests.
> Our `1.3.1` manifests no longer include the tracing components (`istio-tracing`, `kiali`, `grafana`, `jaeger`, etc.)
