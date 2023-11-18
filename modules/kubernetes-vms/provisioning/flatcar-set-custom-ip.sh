#!/usr/bin/env bash

set -x

# Generates a static IP address file for the flatcar VM
# Afterwards, the new IP can be applied with either running `systemctl restart systemd-networkd` or just by rebooting the VM
# On Terraform provisioner, we reboot the VM so the provisioner script can get a proper exit code instead of hanging perpetually
# due to the IP switching and the established network is now disconnected


targetip="$1"
subnetmask="$2"
gateway="$3"
primarydns="$4"
secondarydns="$5"

cat <<EOF | tee /etc/systemd/network/static.network
[Match]
Name=eth0

[Network]
Address=$targetip/$subnetmask
Gateway=$gateway
DNS=$primarydns
DNS=$secondarydns
EOF


# Other things we configure the node with before rebooting

# Disable SELinux because it causes problems with Cilium
# If this was a real production server I'd probably not do this..
echo "Disabling SELinux..."
cp --remove-destination $(readlink -f /etc/selinux/config) /etc/selinux/config
sed 's/permissive/disabled/g' /etc/selinux/config > /etc/selinux/config2
mv /etc/selinux/config2 /etc/selinux/config