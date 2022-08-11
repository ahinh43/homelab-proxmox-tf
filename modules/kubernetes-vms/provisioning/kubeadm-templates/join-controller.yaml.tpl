apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: ${kubernetes_cluster_endpoint}
    token: ${kubernetes_cluster_token}
    caCertHashes:
    - ${kubernetes_cluster_cacert_hash}
controlPlane:
  joinControlPlane:
    localAPIEndpoint: ${kubernetes_controller_local_endpoint}
    certificateKey: ${kubernetes_controller_certificate_key}
nodeRegistration:
  kubeletExtraArgs:
    volume-plugin-dir: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
