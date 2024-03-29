apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
  - token: "${kubeadm_token_1}"
    description: "kubeadm bootstrap token"
    ttl: "24h"
  - token: "${kubeadm_token_2}"
    description: "another bootstrap token"
    usages:
      - authentication
      - signing
    groups:
      - system:bootstrappers:kubeadm:default-node-token
localAPIEndpoint:
  advertiseAddress: "${kubernetes_controller_local_address}"
  bindPort: ${kubernetes_controller_local_port}
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
networking:
  podSubnet: "${kubernetes_pod_subnet}"
  serviceSubnet: "${kubernetes_service_subnet}"
controlPlaneEndpoint: "${kubernetes_api_endpoint}"
controllerManager:
  extraArgs:
    flex-volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd