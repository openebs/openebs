# Redis

This document demonstrates the deployment of Redis as a StatefulSet in a Kubernetes cluster. The user can spawn a Redis StatefulSet that will use OpenEBS as its persistent storage.

## Deploy as a StatefulSet

Deploying Redis as a StatefulSet provides the following benefits:

- Stable unique network identifiers.
- Stable persistent storage.
- Ordered graceful deployment and scaling.
- Ordered graceful deletion and termination.

## Deploy Redis with Persistent Storage

Before getting started check the status of the cluster:

```bash
ubuntu@kubemaster:~kubectl get nodes
NAME            STATUS    AGE       VERSION
kubemaster      Ready     3d        v1.8.2
kubeminion-01   Ready     3d        v1.8.2
kubeminion-02   Ready     3d        v1.8.2

```

Download and apply the Redis YAML from OpenEBS repository:

```bash
ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/redis/redis-statefulset.yml
ubuntu@kubemaster:~kubectl apply -f redis-statefulset.yml

```

Get the status of running pods:

```bash
ubuntu@kubemaster:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                             READY     STATUS    RESTARTS   AGE
default       maya-apiserver-6fc5b4d59c-mg9k2                                  1/1       Running   0          6d
default       openebs-provisioner-6d9b78696d-h647b                             1/1       Running   0          6d
default       pvc-1f305192-ca11-11e7-892e-000c29119159-ctrl-777f4dbd8c-znd7k   1/1       Running   0          19h
default       pvc-1f305192-ca11-11e7-892e-000c29119159-rep-7d9c58bff8-ch6xw    1/1       Running   0          19h
default       pvc-1f305192-ca11-11e7-892e-000c29119159-rep-7d9c58bff8-jnpzn    1/1       Running   0          19h
default       pvc-59eea5e9-ca11-11e7-892e-000c29119159-ctrl-66c4878c46-mjlzl   1/1       Running   0          19h
default       pvc-59eea5e9-ca11-11e7-892e-000c29119159-rep-7c7c5984cd-jb9f6    1/1       Running   0          19h
default       pvc-59eea5e9-ca11-11e7-892e-000c29119159-rep-7c7c5984cd-jml24    1/1       Running   0          19h
default       pvc-e7b2a235-ca10-11e7-892e-000c29119159-ctrl-6478bfbff6-95gm5   1/1       Running   0          19h
default       pvc-e7b2a235-ca10-11e7-892e-000c29119159-rep-f9f46b858-8fmt4     1/1       Running   0          19h
default       pvc-e7b2a235-ca10-11e7-892e-000c29119159-rep-f9f46b858-jt25r     1/1       Running   0          19h
default       rd-0                                                             1/1       Running   0          19h
default       rd-1                                                             1/1       Running   0          19h
default       rd-2                                                             1/1       Running   0          19h
kube-system   etcd-o-master01                                                  1/1       Running   0          6d
kube-system   kube-apiserver-o-master01                                        1/1       Running   0          6d
kube-system   kube-controller-manager-o-master01                               1/1       Running   0          6d
kube-system   kube-dns-545bc4bfd4-m4ngc                                        3/3       Running   0          6d
kube-system   kube-proxy-4ml5l                                                 1/1       Running   0          6d
kube-system   kube-proxy-7jlpf                                                 1/1       Running   0          6d
kube-system   kube-proxy-cxkpc                                                 1/1       Running   0          6d
kube-system   kube-scheduler-o-master01                                        1/1       Running   0          6d
kube-system   weave-net-ctfk4                                                  2/2       Running   0          6d
kube-system   weave-net-dwszp                                                  2/2       Running   0          6d
kube-system   weave-net-pzbb7                                                  2/2       Running   0          6d

```

Get the status of running StatefulSets:

```bash
ubuntu@kubemaster:~$ kubectl get statefulset
NAME      DESIRED   CURRENT   AGE
rd        3         3         19h

```

Get the status of underlying persistent volumes used by Redis StatefulSet:

```bash
ubuntu@kubemaster:~$ kubectl get pvc
NAME           STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
datadir-rd-0   Bound     pvc-e7b2a235-ca10-11e7-892e-000c29119159   1G         RWO            openebs-redis   19h
datadir-rd-1   Bound     pvc-1f305192-ca11-11e7-892e-000c29119159   1G         RWO            openebs-redis   19h
datadir-rd-2   Bound     pvc-59eea5e9-ca11-11e7-892e-000c29119159   1G         RWO            openebs-redis   19h

```

Get the status of the services:

```bash
ubuntu@kubemaster:~kubectl get svc
NAME                                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
kubernetes                                          ClusterIP   10.96.0.1        <none>        443/TCP             6d
maya-apiserver-service                              ClusterIP   10.111.26.252    <none>        5656/TCP            6d
pvc-1f305192-ca11-11e7-892e-000c29119159-ctrl-svc   ClusterIP   10.105.218.103   <none>        3260/TCP,9501/TCP   19h
pvc-59eea5e9-ca11-11e7-892e-000c29119159-ctrl-svc   ClusterIP   10.106.116.112   <none>        3260/TCP,9501/TCP   19h
pvc-e7b2a235-ca10-11e7-892e-000c29119159-ctrl-svc   ClusterIP   10.102.32.23     <none>        3260/TCP,9501/TCP   19h
redis                                               ClusterIP   None             <none>        6379/TCP            19h

```

## Check Redis Replication

Set a key:value pair in the Redis master.

```bash
ubuntu@kubemaster:~kubectl exec rd-0 -- /opt/redis/redis-cli -h rd-0.redis SET replicated:test true
OK

```

Retrieve the value of the key from a Redis slave.

```bash
ubuntu@kubemaster:~kubectl exec rd-2 -- /opt/redis/redis-cli -h rd-0.redis GET replicated:test
true

```