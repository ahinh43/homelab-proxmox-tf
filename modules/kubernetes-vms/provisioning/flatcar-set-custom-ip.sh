#!/usr/bin/env bash

set -euxo pipefail

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