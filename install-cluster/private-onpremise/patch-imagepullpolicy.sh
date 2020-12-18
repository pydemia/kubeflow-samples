#!/bin/bash

set -e

# imagePullPolicy: Always -> IfNotPresent

## Patch `configmap istio-system/istio-sidecar-injector`
kubectl -n istio-system get configmap istio-sidecar-injector -o=jsonpath='{.data.config}' > istio-sidecar-injector-config.yaml && \
    sed 's/imagePullPolicy: "{{ valueOrDefault .Values.global.imagePullPolicy `Always` }}"/imagePullPolicy: "{{ valueOrDefault .Values.global.imagePullPolicy `IfNotPresent` }}"/g' istio-sidecar-injector-config.yaml > istio-sidecar-injector-config-for-private-network.yaml && { \
    cat > patch-istio-sidecar-injector-configmap.yaml <<EOF
data:
  config: |-
EOF
} && \
sed 's/^/    /' istio-sidecar-injector-config-for-private-network.yaml >> patch-istio-sidecar-injector-configmap.yaml && \
    kubectl -n istio-system patch configmap istio-sidecar-injector --patch "$(cat patch-istio-sidecar-injector-configmap.yaml)"

## Patch `statefulset kfserving-system/kfserving-controller-manager`
kubectl -n kfserving-system patch statefulset kfserving-controller-manager --type=json -p='
[
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/0/imagePullPolicy",
        "value": "IfNotPresent"
    },
    {
        "op": "replace",
        "path": "/spec/template/spec/containers/1/imagePullPolicy",
        "value": "IfNotPresent"
    }
]'
