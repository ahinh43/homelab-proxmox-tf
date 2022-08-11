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