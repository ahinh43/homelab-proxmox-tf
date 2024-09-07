#!/usr/bin/env bash

# Script to onboard a node as a new Kubernetes controller node, joining an existing cluster
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better

set -eo pipefail

# Load modules file
source /tmp/kubernetes-modules.sh

kubevip="$1"
untaintnode="$2"

# https://github.com/containernetworking/plugins/releases
CNI_VERSION="v1.4.1"
# https://github.com/kubernetes-sigs/cri-tools/releases
CRICTL_VERSION="v1.29.0"
# https://github.com/kubernetes/release/releases
RELEASE_VERSION="v0.16.7"
# https://github.com/tailscale/tailscale/releases
TAILSCALE_VERSION="1.62.1"

DOWNLOAD_DIR=/opt/bin

#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE="v1.29.3"

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

systemctl enable --now kubelet

kubeadm join --config /tmp/join-controller.yaml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown core:core $HOME/.kube/config

kubectl get pods -A
kubectl get nodes -o wide

# Prepares the VM for use with the FLUO (Flatcar Linux Update Operator), a update agent that works with the Kubernetes cluster to orchestrate updates like draining a node before rebooting

## Ensure the update engine is pointing to the public update server
# and not some localhost url that doesn't work
cat <<EOF | tee /etc/flatcar/update.conf
GROUP=stable
SERVER=https://public.update.flatcar-linux.net/v1/update/
EOF

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

# Enable Kernel modules needed

load_cluster_modules
set_sysctl_parameters

# If the untaint node flag is passed, untaints the primary controller so it can be used as a worker too
if [[ "$untaintnode" = "yes" ]]; then
  echo "Untainting the control plane"
  kubectl taint node $(hostname) node-role.kubernetes.io/control-plane:NoSchedule-
  # Enable the containerd plugin to allow non root containers to mount devices
  # Must take place before kubelet is installed and running

  mkdir -p /etc/containerd
  mkdir -p /etc/systemd/system/containerd.service.d/
  cp /usr/share/containerd/config.toml /etc/containerd/config.toml
  sed -ie 's/^\[plugins."io.containerd.grpc.v1.cri"\].*$/& \ndevice_ownership_from_security_context = true/g' /etc/containerd/config.toml

  cat <<EOF | tee /etc/systemd/system/containerd.service.d/10-use-custom-config.conf
  [Service]
  ExecStart=
  ExecStart=/usr/bin/containerd
EOF

  systemctl daemon-reload
  systemctl restart containerd
fi