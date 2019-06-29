#!/usr/bin/env sh
set -euo pipefail
cp /opt/cilium-portmap.conflist /host/etc/cni/net.d/00-cilium-portmap.conflist
while true; do sleep 5; done