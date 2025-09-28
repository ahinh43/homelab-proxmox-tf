apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: ${kubernetes_cluster_endpoint}
    token: ${kubernetes_cluster_token}
    caCertHashes:
    - ${kubernetes_cluster_cacert_hash}
controlPlane:
nodeRegistration:
  kubeletExtraArgs:
    - name: volume-plugin-dir
      value: "/opt/libexec/kubernetes/kubelet-plugins/volume/exec/"
