cluster:
  name: ${kubernetes_cluster_name}
  id: ${kubernetes_cluster_id}
ipv4NativeRoutingCIDR: 10.0.0.0/8
ipam:
  # -- Configure IP Address Management mode.
  # ref: https://docs.cilium.io/en/stable/network/concepts/ipam/
  mode: "cluster-pool"
  # -- Maximum rate at which the CiliumNode custom resource is updated.
  ciliumNodeUpdateRate: "15s"
  operator:
    # -- IPv4 CIDR list range to delegate to individual nodes for IPAM.
    clusterPoolIPv4PodCIDRList: ${kubernetes_pod_subnet}
    # -- IPv4 CIDR mask size to delegate to individual nodes for IPAM.
    clusterPoolIPv4MaskSize: 24