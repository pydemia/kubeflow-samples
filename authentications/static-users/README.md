
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

```bash
kubectl get configmap dex -n auth -o jsonpath='{.data.config\.yaml}' > dex-config.yaml
```

use [BCrypt](https://passwordhashing.com/BCrypt):

```bash

```