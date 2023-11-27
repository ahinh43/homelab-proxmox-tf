#!/usr/bin/env bash

# Script to create a new Kubernetes worker node from scratch, joining an existing cluster
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better
set -eo pipefail

# Load modules file
source ./kubernetes-modules.sh

unused="$1" # Would be 'make_controller_worker' but we don't use that for workers
longhorn_provision_mount_device="$2"

# https://github.com/containernetworking/plugins/releases
CNI_VERSION="v1.3.0"
# https://github.com/kubernetes-sigs/cri-tools/releases
CRICTL_VERSION="v1.28.0"
# https://github.com/kubernetes/release/releases
RELEASE_VERSION="v0.16.3"

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

systemctl enable --now kubelet

kubeadm join --config /tmp/join-worker.yaml

# Enables iscsid for use with OpenEBS cstor
systemctl enable iscsid.service
systemctl start iscsid.service

# Prepares the VM for use with the FLUO (Flatcar Linux Update Operator), a update agent that works with the Kubernetes cluster to orchestrate updates like draining a node before rebooting
systemctl stop locksmithd.service
systemctl disable locksmithd.service
systemctl mask locksmithd.service

systemctl unmask update-engine.service
systemctl enable update-engine.service
systemctl start update-engine.service


# Enable Kernel modules needed

load_cluster_modules

# Set up and mount a disk, if enabled.

if [[ -n "$longhorn_provision_mount_device" ]]; then
  echo "Formatting and mounting $longhorn_provision_mount_device..."
  mkdir -p /var/lib/longhorn
  umount $longhorn_provision_mount_device || true
  sfdisk --delete $longhorn_provision_mount_device
  echo "y" | mkfs.ext4 $longhorn_provision_mount_device
  name=$(systemd-escape -p --suffix=mount '/var/lib/longhorn')
  cat <<EOF | tee /etc/systemd/system/$name
  Before=local-fs.target
  Description=Longhorn Disk mount
  [Mount]
  What=$longhorn_provision_mount_device
  Where=/var/lib/longhorn
  Type=ext4
  [Install]
  WantedBy=local-fs.target 
EOF
  systemctl daemon-reload
  systemctl enable $name
  systemctl start $name
fi