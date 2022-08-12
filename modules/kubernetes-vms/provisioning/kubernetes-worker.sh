#!/usr/bin/env bash

# Script to create a new Kubernetes cluster from scratch, onboarding this server as the first controller node


kube_endpoint="$1"

CNI_VERSION="v1.1.1"
CRICTL_VERSION="v1.24.2"
RELEASE_VERSION="v0.14.0"
DOWNLOAD_DIR=/opt/bin

RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"

mkdir -p /opt/cni/bin
mkdir -p /etc/systemd/system/kubelet.service.d

curl -sSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" | tar -C /opt/cni/bin -xz
curl -sSL "https://github.com/kubernetes-sigs/cri-tools/releases/download/${CRICTL_VERSION}/crictl-${CRICTL_VERSION}-linux-amd64.tar.gz" | tar -C $DOWNLOAD_DIR -xz
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubelet/lib/systemd/system/kubelet.service" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service
curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/kubepkg/templates/latest/deb/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:${DOWNLOAD_DIR}:g" | tee /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
curl -sSL --remote-name-all https://storage.googleapis.com/kubernetes-release/release/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

chmod +x {kubeadm,kubelet,kubectl}
mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/

systemctl enable --now kubelet

kubeadm join --config /tmp/join-worker.yaml

# Provision the disk used by OpenEBS

# Find the disk that is free. This is probably a REALLY jank method to figure this out
# The device found is in a random letter assigned by Proxmox, but the free device usually has a timestamp that is the oldest modified (likely due to the partitions not being touched on the disk)
device=$(ls -tr /dev/sd* | head -n1)

parted $device mklabel msdos
parted -a optimal $device mkpart primary '0%' '100%'


pvcreate "${device}1"; sleep 2 && vgcreate vg_openebs_pv "${device}1"; sleep 2 && lvcreate -l 100%FREE -n lv_openebs_pv vg_openebs_pv

mkdir -p /var/openebs
mkfs.ext4 /dev/mapper/vg_openebs_pv-lv_openebs_pv
mount /dev/mapper/vg_openebs_pv-lv_openebs_pv /var/openebs


cat <<EOF | tee /etc/systemd/system/var-openebs.mount
[Unit]
Description=OpenEBS PV Mount

[Mount]
What=/dev/mapper/vg_openebs_pv-lv_openebs_pv
Where=/var/openebs
Type=ex4
Options=defaults

[Install]
WantedBy=multi-user.target
EOF

sed 's/After=network-online.target/After=network-online.target var-openebs.mount/g' /etc/systemd/system/kubelet.service > kubelet.modified.service
mv /etc/systemd/system/kubelet.service /etc/systemd/system/kubelet.service.bak
mv kubelet.modified.service /etc/systemd/system/kubelet.service

systemctl daemon-reload
systemctl enable var-openebs.mount