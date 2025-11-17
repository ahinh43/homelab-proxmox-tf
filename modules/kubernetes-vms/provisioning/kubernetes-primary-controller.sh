#!/usr/bin/env bash

# Script to create a new Kubernetes cluster from scratch, onboarding this server as the first controller node
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better

set -eo pipefail
kubevip="$1"
clustername="$2"
untaintnode="$3"
onepasswordtoken="$4"

# Load common file
source /tmp/kubernetes-common.sh

# https://github.com/cilium/cilium-cli/releases
CILIUM_CLI_VERSION="v0.18.3"
# https://github.com/cilium/cilium/releases
CILIUM_VERSION="1.17.4"

GATEWAY_API_VERSION="v1.4.0"

install_kube_binaries


# Set up kube-vip
setup_kube_vip

# Initializes the Kubernetes server
systemctl enable --now kubelet

kubeadm config images pull
kubeadm init --skip-phases=addon/kube-proxy --config kubeadm-config.yaml

setup_kube_home_dir

# Cilium setup

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz{,.sha256sum}
tar xzvfC cilium-linux-amd64.tar.gz $DOWNLOAD_DIR
rm cilium-linux-amd64.tar.gz

sleep 10

cilium version --client
cilium install --version $CILIUM_VERSION -f cilium-values.yaml

kubectl get pods -A
kubectl get nodes -o wide

# Install Gateway API CRDs
kubectl apply --server-side -f https://github.com/kubernetes-sigs/gateway-api/releases/download/${GATEWAY_API_VERSION}/standard-install.yaml

# TODO: Drop experimental CRDs once Cilium adds Gateway API 1.4.0 support
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/${GATEWAY_API_VERSION}/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

URL=$(kubectl config view -ojsonpath='{.clusters[0].cluster.server}')
prefix="https://"
short_url=${URL#"$prefix"}

cat <<EOF | tee worker-join-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: $short_url
    token: $(kubeadm token create)
    caCertHashes:
    - sha256:$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
controlPlane:
nodeRegistration:
  kubeletExtraArgs:
    - name: volume-plugin-dir
      value: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
EOF

chown core:core worker-join-config.yaml
kubeadm init phase upload-certs --upload-certs

setup_flatcar_update_operator

# If the untaint node flag is passed, untaints the primary controller so it can be used as a worker too
if [[ "$untaintnode" = "yes" ]]; then
  echo "Untainting the control plane"
  kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-
  enable_containerd_plugin
fi

# Enable Kernel modules needed

load_cluster_modules
set_sysctl_parameters

sed -i 's/-admin//g' /home/core/.kube/config
sed -i 's/@kubernetes//g' /home/core/.kube/config
sed -i "s/kubernetes/${clustername}/g" /home/core/.kube/config

# Set up onepassword token so that ESO can create the cluster secret store
provision_onepassword "$onepasswordtoken"