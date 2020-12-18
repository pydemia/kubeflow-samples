#!/bin/bash

NETWORK="yjkim-vpc"  # "default" or VPC
SUBNETWORK="yjkim-kube-subnet"

PROJECT_ID="ds-ai-platform"
CLUSTER_NM="kubeflow-alpha"

read -p "Enter cluster-name [$CLUSTER_NM]: " cluster_nm
CLUSTER_NM=${cluster_nm:-$CLUSTER_NM}

REGION="us-central1"
#ZONE="us-central1-a"
CLUSTER_VERSION="1.17.12-gke.1504" # "1.15.9-gke.24"
MASTER_IPV4_CIDR="172.31.12.32/28"

# -- Weird: Not for VMs in subnet, but both crashes with subnet CIDR.
# Message: 
# Retry budget exhausted (80 attempts): 
# Requested CIDR 192.168.0.0/16 for pods is not available in network "yjkim-vpc" for cluster
# Requested CIDR 172.16.0.0/16 for services is not available in network "yjkim-vpc" for cluster

CLUSTER_IPV4_CIDR="10.0.0.0/21"  # The IP address range for the pods in this cluster
SERVICE_IPV4_CIDR="172.19.0.0/16"  # Set the IP range for the services IPs. Can be specified as a netmask size (e.g. '/20') or as in CIDR notion (e.g. '10.100.0.0/20').  Can not be specified unless '--enable-ip-alias' is also specified.

DISK_TYPE="pd-standard"  #  pd-standard, pd-ssd
DISK_SIZE="100GB"  # default: 100GB
IMAGE_TYPE="UBUNTU"  # COS, UBUNTU, COS_CONTAINERD, UBUNTU_CONTAINERD, WINDOWS_SAC, WINDOWS_LTSC (gcloud container get-server-config)
MACHINE_TYPE="n1-standard-8" # 8CPUs, 32GB (gcloud compute machine-types list) <https://cloud.google.com/compute/vm-instance-pricing>

# #--- [GPUs]: Check AZ for GPU model Availability <https://cloud.google.com/compute/docs/gpus#gpus-list> ---#
# # (gcloud compute accelerator-types list) ,count: default 1

# # 1. {Tesla T4: (us-central1-a, us-central1-b, us-central1-f), (asia-northeast3-b, asia-northeast3-c)}
# ACCELERATOR="type=nvidia-tesla-t4,count=1"
# ZONE_NODE_LOCATIONS="us-central1-a,us-central1-b,us-central1-f"

# # 2. {Tesla K80: (us-central1-a, us-central1-c)}
# ACCELERATOR="type=nvidia-tesla-k80,count=1"
# ZONE_NODE_LOCATIONS="us-central1-a,us-central1-c"

# # 3. {Tesla P100: (us-central1-c, us-central1-f)}
# ACCELERATOR="type=nvidia-tesla-p100,count=1"
# ZONE_NODE_LOCATIONS="us-central1-c,us-central1-f"

# # 4. {Tesla V100: (us-central1-a, us-central1-b, us-central1-c, us-central1-f)}
# ACCELERATOR="type=nvidia-tesla-v100,count=1"
# ZONE_NODE_LOCATIONS="us-central1-a,us-central1-b,us-central1-c,us-central1-f"

# #----------------------------------------------------------------------------------------------------------#
# Specifies the reservation for the default initial node pool.
# --reservation=RESERVATION
# The name of the reservation, required when --reservation-affinity=specific.
# --reservation-affinity=RESERVATION_AFFINITY
# The type of the reservation for the default initial node pool. RESERVATION_AFFINITY must be one of: any, none, specific.
#NODE_POOL="ubuntu-cpu"
NUM_NODES="1"  # The number of nodes to be created in each of the cluster's zones. default: 3
MIN_NODES="0"  # Minimum number of nodes in the node pool. Ignored unless `--enable-autoscaling` is also specified.
MAX_NODES="4" # Maximum number of nodes in the node pool. Ignored unless `--enable-autoscaling` is also specified.
MAX_NODES_PER_POOL="100"  # Defaults to 1000 nodes, but can be set as low as 100 nodes per pool on initial create.
MAX_PODS_PER_NODE="110"  # default=110, Must be used in conjunction with '--enable-ip-alias'.
NETWORK="yjkim-vpc"  # "default" or VPC
SUBNETWORK="yjkim-kube-subnet"
#yjkim-kube-natpublic
TAGS="yjkim-kube-instance,yjkim-kube-istio,yjkim-kube-knative,yjkim-kube-kafka,yjkim-kube-subnetall"  # (https://cloud.google.com/compute/docs/labeling-resources), tag1,tag2
SERVICE_ACCOUNT="airuntime@ds-ai-platform.iam.gserviceaccount.com"

WORKLOAD_POOL="${PROJECT_ID}.svc.id.goog" # Enable Workload Identity on the cluster. When enabled, Kubernetes service accounts will be able to act as Cloud IAM Service Accounts, through the provided workload pool. Currently, the only accepted workload pool is the workload pool of the Cloud project containing the cluster, `PROJECT_ID.svc.id.goog.`
WORKLOAD_METADATA="GKE_METADATA"
#--security-group=SECURITY_GROUP  # The name of the RBAC security group for use with Google security groups in Kubernetes RBAC (https://kubernetes.io/docs/reference/access-authn-authz/rbac/). If unspecified, no groups will be returned for use with RBAC.
# ISTIO_CONFIG="auth=MTLS_PERMISSIVE"
METADATA="disable-legacy-endpoints=true"
LABELS="cz_owner=youngju_kim,application=kubeflow,kubeflow-version=1-2,kfserving-version=0-4-1"
DESCRIPTION="A testbed Kubernetes cluster for Kubeflow."
SOURCE_NETWORK_CIDRS=""
SCOPES="gke-default,pubsub,compute-rw,storage-full,trace,monitoring-write"

# --no-issue-client-certificate \
# https://cloud.google.com/kubernetes-engine/docs/how-to/private-clusters#all_access
gcloud beta container clusters create \
    $CLUSTER_NM \
    --region=$REGION \
    --cluster-version=$CLUSTER_VERSION \
    --enable-autoscaling \
    --min-nodes=$MIN_NODES \
    --max-nodes=$MAX_NODES \
    --enable-vertical-pod-autoscaling \
    --enable-ip-alias \
    --enable-private-nodes \
    --issue-client-certificate \
    --no-enable-basic-auth \
    --no-enable-master-authorized-networks \
    --master-ipv4-cidr=$MASTER_IPV4_CIDR \
    --cluster-ipv4-cidr=$CLUSTER_IPV4_CIDR \
    --services-ipv4-cidr=$SERVICE_IPV4_CIDR \
    --disk-type=$DISK_TYPE \
    --disk-size=$DISK_SIZE \
    --image-type=$IMAGE_TYPE \
    --machine-type=$MACHINE_TYPE \
    --num-nodes=$NUM_NODES \
    --max-nodes-per-pool=$MAX_NODES_PER_POOL \
    --max-pods-per-node=$MAX_PODS_PER_NODE \
    --network=$NETWORK \
    --subnetwork=$SUBNETWORK \
    --tags=$TAGS \
    --service-account=$SERVICE_ACCOUNT \
    --workload-pool=$WORKLOAD_POOL \
    --workload-metadata=$WORKLOAD_METADATA \
    --shielded-integrity-monitoring \
    --enable-stackdriver-kubernetes \
    --enable-autorepair \
    --no-enable-autoupgrade \
    --enable-intra-node-visibility \
    --enable-shielded-nodes \
    --metadata=$METADATA \
    --labels=$LABELS \
    --addons HorizontalPodAutoscaling,HttpLoadBalancing \
    --scopes=$SCOPES

# --no-enable-master-authorized-networks disables authorized networks for the cluster.
# --enable-ip-alias makes the cluster VPC-native.
# --enable-private-nodes indicates that the cluster's nodes do not have external IP addresses.
# --master-ipv4-cidr 172.16.0.32/28 specifies an RFC 1918 range for the master. This setting is permanent for this cluster. The use of non RFC 1918 reserved IPs is also supported (beta).
# --no-enable-basic-auth indicates to disable basic auth for the cluster.
# --no-issue-client-certificate disables issuing a client certificate.



# --addons HorizontalPodAutoscaling,HttpLoadBalancing,Istio,ApplicationManager \
# --istio-config=$ISTIO_CONFIG \

# gcloud beta container clusters create \
#     $CLUSTER_NM \
#     --region=$REGION \
#     #--zone=$ZONE \
#     #--workload-pool=$WORKLOAD_POOL \
#     --cluster-version=$CLUSTER_VERSION \
#     --enable-autoscaling \
#     --min-nodes=$MIN_NODES \
#     --max-nodes=$MAX_NODES \
#     --enable-vertical-pod-autoscaling \
#     --enable-ip-alias \
#     #--enable-private-endpoint \
#     --enable-private-nodes \
#     --no-enable-master-authorized-networks \
#     # --enable-master-global-access \
#     # --enable-master-authorized-networks \
#     #   --master-authorized-networks=SOURCE_NETWORK_CIDRS \
#     --master-ipv4-cidr=$MASTER_IPV4_CIDR \
#     #--cluster-ipv4-cidr=$CLUSTER_IPV4_CIDR \
#     #--services-ipv4-cidr=$SERVICE_IPV4_CIDR \
#     --disk-type=$DISK_TYPE \
#     --disk-size=$DISK_SIZE \
#     --image-type=$IMAGE_TYPE \
#     --machine-type=$MACHINE_TYPE \
#     #--accelerator=ACCELERATOR \
#     #--node-locations=$ZONE_NODE_LOCATIONS \
#     --num-nodes=$NUM_NODES \
#     --max-nodes-per-pool=$MAX_NODES_PER_POOL \
#     --max-pods-per-node=$MAX_PODS_PER_NODE \
#     --network=$NETWORK \
#     --subnetwork=$SUBNETWORK \
#     --tags=$TAGS \
#     --service-account=$SERVICE_ACCOUNT \
#     --shielded-integrity-monitoring \
#     --enable-stackdriver-kubernetes \
#     --enable-autorepair \
#     --no-enable-autoupgrade \
#     --enable-intra-node-visibility \
#     --enable-shielded-nodes \
#     --metadata=$METADATA \
#     --labels=$LABELS \
#     --addons HorizontalPodAutoscaling,HttpLoadBalancing,Istio,CloudRun \
#     --istio-config=$ISTIO_CONFIG \
#     --scopes="gke-default"