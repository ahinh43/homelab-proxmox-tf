apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: ${kubernetes_cluster_endpoint}
    token: ${kubernetes_cluster_token}
    caCertHashes:
    - ${kubernetes_cluster_cacert_hash}
controlPlane:
  localAPIEndpoint:
    advertiseAddress: "${kubernetes_controller_local_address}"
    bindPort: ${kubernetes_controller_local_port}
  certificateKey: ${kubernetes_controller_certificate_key}
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
