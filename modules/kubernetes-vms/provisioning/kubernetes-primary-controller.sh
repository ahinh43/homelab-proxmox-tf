#!/usr/bin/env bash

# Script to create a new Kubernetes cluster from scratch, onboarding this server as the first controller node
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better

set -eo pipefail
kubevip="$1"
clustername="$2"
untaintnode="$3"

# Load modules file
source ./kubernetes-modules.sh

# https://github.com/containernetworking/plugins/releases
CNI_VERSION="v1.3.0"
# https://github.com/kubernetes-sigs/cri-tools/releases
CRICTL_VERSION="v1.28.0"
# https://github.com/kubernetes/release/releases
RELEASE_VERSION="v0.16.4"
# https://github.com/tailscale/tailscale/releases
TAILSCALE_VERSION="1.52.1"
# https://github.com/cilium/cilium-cli/releases
CILIUM_CLI_VERSION="v0.15.13"
# https://github.com/cilium/cilium/releases
CILIUM_VERSION="1.14.4"

DOWNLOAD_DIR=/opt/bin

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

if systemctl list-unit-files | grep -q "kubelet"; then 
  echo "Existing Kubelet service already found. To reprovision the node consider recreating it from scratch and rerunning this script.";
  exit 0
else 
  echo "Kubelet not found. Moving on!"; 
fi

mkdir -p /opt/cni/bin
mkdir -p /etc/systemd/system/kubelet.service.d

curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl -sSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl -sSL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/


# Set up kube-vip

export VIP="$kubevip"
export INTERFACE=eth0
mkdir -p /etc/kubernetes/manifests
KVVERSION=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
ctr images pull ghcr.io/kube-vip/kube-vip:$KVVERSION

ctr run --rm --net-host ghcr.io/kube-vip/kube-vip:$KVVERSION vip /kube-vip manifest pod \
    --interface $INTERFACE \
    --address $VIP \
    --controlplane \
    --services \
    --arp \
    --leaderElection | tee /etc/kubernetes/manifests/kube-vip.yaml

# Initializes the Kubernetes server
systemctl enable --now kubelet

kubeadm config images pull
kubeadm init --config kubeadm-config.yaml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown core:core $HOME/.kube/config

# Cilium setup

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz{,.sha256sum}
tar xzvfC cilium-linux-amd64.tar.gz $DOWNLOAD_DIR
rm cilium-linux-amd64.tar.gz

sleep 10

cilium version --client
cilium install --version $CILIUM_VERSION -f cilium-values.yaml

kubectl get pods -A
kubectl get nodes -o wide

URL=$(kubectl config view -ojsonpath='{.clusters[0].cluster.server}')
prefix="https://"
short_url=${URL#"$prefix"}

cat <<EOF | tee worker-join-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
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
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
EOF

chown core:core worker-join-config.yaml
kubeadm init phase upload-certs --upload-certs

# Prepares the VM for use with the FLUO (Flatcar Linux Update Operator), a update agent that works with the Kubernetes cluster to orchestrate updates like draining a node before rebooting
systemctl stop locksmithd.service
systemctl disable locksmithd.service
systemctl mask locksmithd.service

systemctl unmask update-engine.service
systemctl enable update-engine.service
systemctl start update-engine.service

# Create install tailscale script. It's not run automatically because A) Free tailscale users get a limited device count and B) it requires web authentication which is a user manual input

cat <<EOF | tee install-tailscale.sh
#!/usr/bin/env bash
wget https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSION}_amd64.tgz
tar xvf tailscale_${TAILSCALE_VERSION}_amd64.tgz
cp tailscale_${TAILSCALE_VERSION}_amd64/tailscaled /opt/bin/tailscaled
cp tailscale_${TAILSCALE_VERSION}_amd64/tailscale /opt/bin/tailscale

sed -i 's/\/usr\/sbin/\/opt\/bin/g' tailscale_${TAILSCALE_VERSION}_amd64/systemd/tailscaled.service

cp tailscale_${TAILSCALE_VERSION}_amd64/systemd/tailscaled.service /etc/systemd/system/tailscaled.service
cp tailscale_${TAILSCALE_VERSION}_amd64/systemd/tailscaled.defaults /etc/default/tailscaled

systemctl daemon-reload

systemctl start tailscaled.service
systemctl enable tailscaled.service

/opt/bin/tailscale up --accept-dns=false
EOF
chmod +x install-tailscale.sh

# If the untaint node flag is passed, untaints the primary controller so it can be used as a worker too
if [[ "$untaintnode" = "yes" ]]; then
  echo "Untainting the control plane"
  kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-
fi

# Enable Kernel modules needed

load_cluster_modules
set_sysctl_parameters

sed -i 's/-admin//g' /home/core/.kube/config
sed -i 's/@kubernetes//g' /home/core/.kube/config
sed -i "s/kubernetes/${clustername}/g" /home/core/.kube/config