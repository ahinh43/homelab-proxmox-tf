#!/usr/bin/env bash


install_kube_binaries() {
  # https://github.com/containernetworking/plugins/releases
  CNI_VERSION="v1.6.1"
  # https://github.com/kubernetes-sigs/cri-tools/releases
  CRICTL_VERSION="v1.32.0"
  # https://github.com/kubernetes/release/releases
  RELEASE_VERSION="v0.17.12"

  DOWNLOAD_DIR=/opt/bin

  #RELEASE="$(curl -sSL https://dl.k8s.io/release/stable.txt)"
  RELEASE="v1.32.0"


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
  curl -sSL --remote-name-all https://dl.k8s.io/${RELEASE}/bin/linux/amd64/{kubeadm,kubelet,kubectl}

  chmod +x {kubeadm,kubelet,kubectl}
  mv {kubeadm,kubelet,kubectl} $DOWNLOAD_DIR/
}


enable_containerd_plugin() {
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
}

setup_flatcar_update_operator() {

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

}

setup_kube_vip() {
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
}


setup_kube_home_dir() {
  mkdir -p $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown core:core $HOME/.kube/config
}

load_cluster_modules() {
  modules=( 
    br_netfilter 
    iptable_mangle 
    iptable_nat
    iptable_raw
    xt_REDIRECT
    xt_connmark
    xt_conntrack
    xt_mark
    xt_owner
    xt_tcpudp
    xt_multiport
    vhost
    vhost_net
  )

  for module in ${modules[@]}; do
    echo "Seeing if $module is already loaded..."
    if lsmod | grep -wq "^${module}"; then
      echo "$module is already loaded!"
      continue
    else
      echo "$module is not loaded. Enabling and creating systemd file..."
      modprobe $module
      cat <<EOF | tee /etc/modules-load.d/$module.conf
# Load $module at boot
$module
EOF
    fi
  done
}

set_sysctl_parameters() {
  parameters=( 
    fs.inotify.max_user_instances=1024
    fs.inotify.max_user_watches=1048576
  )
  ruleid=100
  for parameter in ${parameters[@]}; do
    parameterName="$(sed 's/=.*//g' <<< $parameter)"
    parameterFilePath="$(sed 's/\./\//g' <<< $parameterName)"
    parameterValue="$(sed 's/.*=//g' <<< $parameter)"
    echo "Checking sysctl value for $parameter..."
    originalValue=$(cat /proc/sys/$parameterFilePath)
    if [[ $originalValue = $parameterValue ]]; then
      echo "The current value for $parameter matches the desired value. Ignoring..."
    else
      echo "Setting $parameter to $parameterValue..."
      sysctl -w "$parameter"
      fileName="$(sed 's/\./-/g' <<< $parameterName)"
      cat <<EOF | tee /etc/sysctl.d/$ruleid-$fileName.conf
$parameter
EOF
    ruleid=$((ruleid+=1))
    fi
  done
}