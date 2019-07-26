If you are using Cilium and would like to use `hostPort` on your workloads (without `hostNetwork: true`), then you will need to [enable support via configuration](http://docs.cilium.io/en/v1.4/kubernetes/configuration/?highlight=portmap#enabling-hostport-support-via-cni-configuration).

## Include inline to the container postStart lifecycle hook

We 1. tell Cilium not to drop it's own config via the `CILIUM_CNI_CONF` env, and 2. Update the `postStart` lifecycle hook where Cilium does a `/cni-install.sh` already, to include the writing of a CNI config enabling portmap.

```
kubectl edit ds cilium -n kube-system
```

Add this under the container `env`
```yaml
# We drop our own CNI config with portmap enabled, so this tells
# Cilium not to write one.
- name: CILIUM_CNI_CONF
    value: /dev/null
```

Replace this

```yaml
lifecycle:
    postStart:
    exec:
        command:
        - /cni-install.sh
    preStop:
    exec:
        command:
        - /cni-uninstall.sh
```

with

```yaml
lifecycle:
    postStart:
    exec:
        command:
        - sh
        - -c
        - "echo '{\"cniVersion\": \"0.3.1\", \"name\": \"portmap\", \"plugins\": [{\"name\": \"cilium\", \"type\": \"cilium-cni\"}, {\"type\": \"portmap\", \"capabilities\": {\"portMappings\": true}}]}' > /host/etc/cni/net.d/05-cilium.conflist && /cni-install.sh"
    preStop:
    exec:
        command:
        - sh
        - -c
        - "/cni-uninstall.sh && rm /host/etc/cni/net.d/05-cilium.conflist"
```


## Deploy as an initContainer (outdated)

The most reliable way to install this is as an `initContainer` on the existing Cilium agent Daemonset.

Add the following to the `cilium` DaemonSet under `initContainers` as the first in the list:
```
      - name: cilium-portmap
        image: snormore/cilium-portmap-init
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - mountPath: /host/etc/cni/net.d
          name: etc-cni-netd
```

## Deploy as a DaemonSet (outdated)

You can deploy as a separate DaemonSet, but keep in mind that there can be a race condition between Cilium, our portmap DaemonSet, and any workloads/pods you deploy at the same time. If you see that your `hostPort` is not in effect, you may have to restart the pod for Cilium/CNI to detect it and add the necessary `iptables` rule. 

```bash
kubectl apply -f https://raw.githubusercontent.com/snormore/cilium-portmap/master/DaemonSet/daemonset.yaml
```

## Example (outdated)

Let's say you want to deploy a workload that looks something like this:

```yaml
apiVersion: extensions/v1beta1
kind: Deployment
metadata:
  name: hello
spec:
  replicas: 1
  template:
    metadata:
      labels:
        app: hello
    spec:
      containers:
      - name: hello
        image: snormore/hello
        ports:
        - containerPort: 80
          hostPort: 8888
          protocol: TCP

```

Specifically notice the `hostPort` configuration:

```yaml
        - containerPort: 80
          hostPort: 8888
          protocol: TCP
```

If you deploy this workload, a pod will appear on a node serving port `80` via `PodIP`, but when you try to hit `8888` via `HostIP` from another workload on another node, it doesn't work as expected. This is because you need to [enable support via configuration](http://docs.cilium.io/en/v1.4/kubernetes/configuration/?highlight=portmap#enabling-hostport-support-via-cni-configuration) by adding a configuration to `/etc/cni/net.d/00-cilium-portmap.conflist` that looks like the following:

```json
{
    "name": "cilium-portmap",
    "plugins": [
            {
                    "type": "cilium-cni"
            },
            {
                    "type": "portmap",
                    "capabilities": { "portMappings": true }
            }
    ]
}
```

So let's do that by deploying our `cilium-portmap` DaemonSet:

```bash
kubectl apply -f https://raw.githubusercontent.com/snormore/cilium-portmap/master/daemonset.yaml
```

After this, you should be able to hit `8888` via `HostIP` from another workload on another node. 🎉
