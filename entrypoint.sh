#!/usr/bin/env bash
set -xeuo pipefail
mv /opt/cilium-portmap.conflist /host_etc_cni_netd/00-cilium-portmap.conflist
sleep infinity