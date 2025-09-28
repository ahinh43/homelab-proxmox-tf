apiVersion: kubeadm.k8s.io/v1beta4
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
    - name: volume-plugin-dir
      value: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"

---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
networking:
  podSubnet: "${kubernetes_pod_subnet}"
  serviceSubnet: "${kubernetes_service_subnet}"
controlPlaneEndpoint: "${kubernetes_api_endpoint}"
controllerManager:
  extraArgs:
    - name: flex-volume-plugin-dir
      value: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
kubeReserved:
  cpu: 100m
  memory: 1024Mi
  ephemeral-storage: 1Gi
systemReserved:
  cpu: 100m
  memory: 100Mi
  ephemeral-storage: 1Gi