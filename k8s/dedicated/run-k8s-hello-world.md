# Running Hello World App on Kubernetes Cluster

In this example, we will run a simple hello-world web application, that responds with "Hello World" for an HTTP request. The web application Docker image is available at [tutum/hello-world](https://hub.docker.com/r/tutum/hello-world/). 

### Prerequisites

Verify that your Kubernetes Cluster is up and running.

```
ubuntu-host:~/$ vagrant status
Current machine states:

kubemaster-01             running (virtualbox)
kubeminion-01             running (virtualbox)
omm-01                    running (virtualbox)
osh-01                    running (virtualbox)
```

Check the Kubernetes Node status is ready
```
ubuntu-host:~/$ vagrant ssh kubemaster-01
ubuntu@kubemaster-01:~$ kubectl get nodes
NAME            STATUS         AGE
kubemaster-01   Ready,master   26m
kubeminion-01   Ready          22m
```

Check the Kubernetes system services are running

```
ubuntu@kubemaster-01:~$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                    READY     STATUS    RESTARTS   AGE
kube-system   dummy-2088944543-9m94d                  1/1       Running   0          27m
kube-system   etcd-kubemaster-01                      1/1       Running   0          26m
kube-system   kube-apiserver-kubemaster-01            1/1       Running   0          27m
kube-system   kube-controller-manager-kubemaster-01   1/1       Running   0          26m
kube-system   kube-discovery-1769846148-sstmc         1/1       Running   0          27m
kube-system   kube-dns-2924299975-s779z               4/4       Running   0          26m
kube-system   kube-proxy-40xr6                        1/1       Running   0          22m
kube-system   kube-proxy-k7x46                        1/1       Running   0          25m
kube-system   kube-scheduler-kubemaster-01            1/1       Running   0          27m
kube-system   weave-net-2qw1g                         2/2       Running   0          26m
kube-system   weave-net-c577k                         2/2       Running   0          22m
ubuntu@kubemaster-01:~$ 
```

### Pod Spec

The application in kubernetes can be launched directly through kubectl commands or through an yaml spec file. This example uses an spec file, that is shipped with the kubemaster. 

```
ubuntu@kubemaster-01:~$ cd demo/k8s/spec/
ubuntu@kubemaster-01:~/demo/k8s/spec$ cat demo-hello-world.yaml 
apiVersion: v1
kind: Pod
metadata:
  name: hello-world
spec:
  containers:
  - image: tutum/hello-world
    imagePullPolicy: IfNotPresent
    name: hello-world
    ports:
    - containerPort: 8080

ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

### Launch Application

Use the kubectl to create the pod. 
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl create -f demo-hello-world.yaml 
pod "hello-world" created
```

The pod will be scheduled to be created on the minion. The image will be downloaded and launched. 
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl get pods
NAME          READY     STATUS              RESTARTS   AGE
hello-world   0/1       ContainerCreating   0          3s
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

The progress can be tracked using:
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl describe pod hello-world
```
Check the Events for the current state of the launch - scheduling, pulling, starting, etc., 



### Access the application

Check that the hello-world pod moved to running state. 
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl get pods
NAME          READY     STATUS    RESTARTS   AGE
hello-world   1/1       Running   0          4m
ubuntu@kubemaster-01:~/demo/k8s/spec$ 
```

The pod will be assigned an IP address. This can be obtained through the kubectl describe.
```
ubuntu@kubemaster-01:~/demo/k8s/spec$ kubectl describe pod hello-world
Name:		hello-world
Namespace:	default
Node:		kubeminion-01/172.28.128.4
Start Time:	Fri, 24 Feb 2017 12:14:08 +0000
Labels:		<none>
Status:		Running
IP:		10.44.0.1
Controllers:	<none>
Containers:
  hello-world:
    Container ID:	docker://ec503d7a40fad9669f33bb1ab432c02b9ca55364d4d0744793a8e2150d849b45
    Image:		tutum/hello-world
```
IP address assigned is 10.44.0.1 and this is accessible across the Kubernetes Cluster. From either the master or the minion, issue the curl to check that pod is running.

```
ubuntu@kubemaster-01:~/demo/k8s/spec$ curl 10.44.0.1
```
