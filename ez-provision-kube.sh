#!/usr/bin/env bash

# Dirty script that blast provisions all other nodes in kube1

cluster="$1"

if [[ "$cluster" = "kube" ]]; then
  tf apply -target 'module.kube_controller_2' -auto-approve && \
  tf apply -target 'module.kube_controller_3' -auto-approve && \
  tf apply -target 'module.kube_worker_1' -auto-approve && \
  tf apply -target 'module.kube_worker_2' -auto-approve && \
  tf apply -target 'module.kube_worker_3' -auto-approve
fi

if [[ "$cluster" = "kube2" ]]; then
  tf apply -target 'module.kube2_controller_2' -auto-approve && \
  tf apply -target 'module.kube2_controller_3' -auto-approve
fi