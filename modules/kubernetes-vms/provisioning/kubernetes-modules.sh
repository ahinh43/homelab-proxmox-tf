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
  echo "Sysctl set parameters called. Nothing to see here!"
}