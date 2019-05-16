If you are using Cilium and would like to use `hostPort` on your workloads (without `hostNetwork: true`), then you will need to [enable support via configuration](http://docs.cilium.io/en/v1.4/kubernetes/configuration/?highlight=portmap#enabling-hostport-support-via-cni-configuration). This Docker image and DaemonSet does exactly that by adding a `/etc/cni/net.d/00-cilium-portmap.conflist` to every node in your Kubernetes cluster.

## Deploy

```bash
kubectl apply -f https://raw.githubusercontent.com/snormore/cilium-portmap/master/daemonset.yaml
```

## Example

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
    "cniVersion": "0.3.1",
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