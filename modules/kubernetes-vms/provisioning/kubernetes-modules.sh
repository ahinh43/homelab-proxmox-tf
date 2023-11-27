#!/usr/bin/env bash

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