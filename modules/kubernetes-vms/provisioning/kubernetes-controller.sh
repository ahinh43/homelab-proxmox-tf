#!/usr/bin/env bash

# Script to onboard a node as a new Kubernetes controller node, joining an existing cluster
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better

set -eo pipefail

# Load common file
source /tmp/kubernetes-common.sh

kubevip="$1"
untaintnode="$2"

install_kube_binaries

setup_kube_vip

systemctl enable --now kubelet

kubeadm join --config /tmp/join-controller.yaml

setup_kube_home_dir

kubectl get pods -A
kubectl get nodes -o wide

setup_flatcar_update_operator

# Enable Kernel modules needed

load_cluster_modules
set_sysctl_parameters

# If the untaint node flag is passed, untaints the primary controller so it can be used as a worker too
if [[ "$untaintnode" = "yes" ]]; then
  echo "Untainting the control plane"
  kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-
  enable_containerd_plugin
fi