#!/usr/bin/env bash

# Script to onboard a node as a new Kubernetes controller node, joining an existing cluster
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better

kube_endpoint="$1"

CNI_VERSION="v1.2.0"
CRICTL_VERSION="v1.26.1"
RELEASE_VERSION="v0.15.0"
TAILSCALE_VERSION="1.38.1"
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

kubeadm join --config /tmp/join-controller.yaml

mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown core:core $HOME/.kube/config

kubectl get pods -A
kubectl get nodes -o wide

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