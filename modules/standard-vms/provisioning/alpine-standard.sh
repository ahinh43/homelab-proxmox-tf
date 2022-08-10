#!/usr/bin/env ash

apk update
apk upgrade
apk add curl \
  wget \
  htop \
  zip \
  unzip \
  jq

rm -rf /var/cache/apk