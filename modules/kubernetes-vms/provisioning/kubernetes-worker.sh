#!/usr/bin/env bash

# Script to create a new Kubernetes worker node from scratch, joining an existing cluster
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better
set -eo pipefail

# Load common file
source /tmp/kubernetes-common.sh

install_kube_binaries

enable_containerd_plugin

systemctl enable --now kubelet

kubeadm join --config /tmp/join-worker.yaml

setup_flatcar_update_operator

# Enable Kernel modules needed

load_cluster_modules
set_sysctl_parameters