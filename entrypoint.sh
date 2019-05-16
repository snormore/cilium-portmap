#!/usr/bin/env bash
set -euo pipefail
while :; do
    if [ ! -f /host_etc_cni_netd/00-cilium-portmap.conflist ]; then
        cp /opt/cilium-portmap.conflist /host_etc_cni_netd/00-cilium-portmap.conflist
    fi
    sleep 60
done