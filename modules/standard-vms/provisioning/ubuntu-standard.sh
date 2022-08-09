#!/usr/bin/env bash

## Standard Ubuntu VM/LXC Container provisioner
# Updates the OS and installs some packages

hostname="$1"

# Update to the latest packages
apt-get update
apt-get upgrade -y

# Install base packages
apt-get install -y \
  curl \
  wget \
  htop \
  zip \
  unzip \
  jq

# Set the hostname of the container
hostnamectl set-hostname "$hostname"