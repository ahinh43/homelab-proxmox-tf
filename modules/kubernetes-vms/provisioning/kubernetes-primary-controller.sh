#!/usr/bin/env bash

# Script to create a new Kubernetes cluster from scratch, onboarding this server as the first controller node
# A good chunk of this script was brought in from this blog: https://suraj.io/post/2021/01/kubeadm-flatcar/
# Some modifications made to suit this environment's needs better

set -euo pipefail
kubevip="$1"

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

# Kubernetes CNI installation
# Now with cilium!
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/master/stable.txt)
CLI_ARCH=amd64
mkdir -p ${HOME}/.bin
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz ${HOME}/.bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

export PATH="$PATH:${HOME}/.bin"

cilium install
cilium status --wait
cilium connectivity test

# General kubectl commands to validate the installation of the cluster
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