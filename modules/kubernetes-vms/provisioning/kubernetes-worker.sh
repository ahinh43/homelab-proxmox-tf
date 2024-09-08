#!/usr/bin/env bash

# Script to create a new Kubernetes worker node from scratch, joining an existing cluster
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better
set -eo pipefail

# Load modules file
source /tmp/kubernetes-modules.sh

unused="$1" # Would be 'make_controller_worker' but we don't use that for workers
longhorn_provision_mount_device="$2"

# https://github.com/containernetworking/plugins/releases
CNI_VERSION="v1.5.1"
# https://github.com/kubernetes-sigs/cri-tools/releases
CRICTL_VERSION="v1.31.1"
# https://github.com/kubernetes/release/releases
RELEASE_VERSION="v0.17.3"

DOWNLOAD_DIR=/opt/bin

#RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
RELEASE="v1.31.0"


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

systemctl enable --now kubelet

kubeadm join --config /tmp/join-worker.yaml

# Enables iscsid for use with OpenEBS cstor
systemctl enable iscsid.service
systemctl start iscsid.service

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


# Enable Kernel modules needed

load_cluster_modules
set_sysctl_parameters