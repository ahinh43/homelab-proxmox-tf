#!/usr/bin/env bash

set -euxo pipefail

# Generates a static IP address file for the flatcar VM


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