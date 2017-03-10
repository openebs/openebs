## Introduction

This guide will contain various steps that needs to be followed in a K8s deployment
with respect to dynamic storage provisioning.

### Steps followed by the Operator

- Create persistent volume storage class

```bash
ubuntu@kubemaster-01:~$ kubectl create -f /vagrant/slow-gce-sc.yaml 

storageclass "slow-gce-sc" created
```

- List all persistent volume storage classes

```bash
ubuntu@kubemaster-01:~$ kubectl get storageclasses

NAME          TYPE
fast-ebs-sc   kubernetes.io/aws-ebs
fast-gce-sc   kubernetes.io/gce-pd
slow-ebs-sc   kubernetes.io/aws-ebs
slow-gce-sc   kubernetes.io/gce-pd
```

- Create a persistent volume claim

```bash
ubuntu@kubemaster-01:~$ kubectl create -f /vagrant/fast-ebs-pvc.yaml 

persistentvolumeclaim "fast-ebs-pvc" created
```

- List all persistent volume claims

```bash
ubuntu@kubemaster-01:~$ kubectl get pvc

NAME           STATUS    VOLUME    CAPACITY   ACCESSMODES   AGE
fast-ebs-pvc   Pending                                      6s
```

- Create a pod

```bash
ubuntu@kubemaster-01:~$ kubectl create -f /vagrant/my-nginx-pod.yaml 

pod "my-nginx-pod" created
```

- List all the pods

```bash
ubuntu@kubemaster-01:~$ kubectl get pod

NAME           READY     STATUS    RESTARTS   AGE
my-nginx-pod   0/1       Pending   0          9s

ubuntu@kubemaster-01:~$ kubectl get po

NAME           READY     STATUS    RESTARTS   AGE
my-nginx-pod   0/1       Pending   0          19s

ubuntu@kubemaster-01:~$ kubectl get pods

NAME           READY     STATUS    RESTARTS   AGE
my-nginx-pod   0/1       Pending   0          20s
```

### Troubleshoot

- Some of the **generic checks** that can be done to troubleshoot

  - Was the volume plugin installed ?
  - Did you go through the kubelet logs ?
  - Did you go through the kube-controller-manager logs ?
  - What is the verbose mode you are operating at e.g. -v 5 ?


- Verify the **storage classes**

```bash
ubuntu@kubemaster-01:~$ kubectl describe storageclasses
Name:		fast-ebs-sc
IsDefaultClass:	No
Annotations:	<none>
Provisioner:	kubernetes.io/aws-ebs
Parameters:	type=gp2
No events.


Name:		fast-gce-sc
IsDefaultClass:	No
Annotations:	<none>
Provisioner:	kubernetes.io/gce-pd
Parameters:	type=pd-ssd
No events.


Name:		slow-ebs-sc
IsDefaultClass:	No
Annotations:	<none>
Provisioner:	kubernetes.io/aws-ebs
Parameters:	iopsPerGB=10,type=io1,zone=us-east-1d
No events.


Name:		slow-gce-sc
IsDefaultClass:	No
Annotations:	<none>
Provisioner:	kubernetes.io/gce-pd
Parameters:	type=pd-standard
No events.

```

- Verify **pvc**

```bash
ubuntu@kubemaster-01:~$ kubectl describe pvc

Name:		fast-ebs-pvc
Namespace:	default
StorageClass:	fast-ebs-sc
Status:		Pending
Volume:
Labels:		<none>
Capacity:	
Access Modes:	
Events:
  FirstSeen	LastSeen	Count	From				SubObjectPath	Type		Reason			Message
  ---------	--------	-----	----				-------------	--------	------			-------
  21m		14s		85	{persistentvolume-controller }			Warning		ProvisioningFailed	no volume plugin matched
```

- Verify **pod**

```bash
ubuntu@kubemaster-01:~$ kubectl describe po

Name:		my-nginx-pod
Namespace:	default
Node:		/
Labels:		<none>
Status:		Pending
IP:
Controllers:	<none>
Containers:
  my-nginx-fe-con:
    Image:	dockerfile/nginx
    Port:	
    Volume Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-r6hs4 (ro)
      /var/www/html from my-nginx-pd (rw)
    Environment Variables:	<none>
Conditions:
  Type		Status
  PodScheduled 	False 
Volumes:
  my-nginx-pd:
    Type:	PersistentVolumeClaim (a reference to a PersistentVolumeClaim in the same namespace)
    ClaimName:	fast-ebs-pvc
    ReadOnly:	false
  default-token-r6hs4:
    Type:	Secret (a volume populated by a Secret)
    SecretName:	default-token-r6hs4
QoS Class:	BestEffort
Tolerations:	<none>
Events:
  FirstSeen	LastSeen	Count	From			SubObjectPath	Type		Reason			Message
  ---------	--------	-----	----			-------------	--------	------			-------
  4m		16s		20	{default-scheduler }			Warning		FailedScheduling	no nodes available to schedule pods
```

- Verify **pods** from system namespace as well

```bash
ubuntu@kubemaster-01:~$ kubectl get pods --all-namespaces

NAMESPACE     NAME                                    READY     STATUS              RESTARTS   AGE
default       my-nginx-pod                            0/1       Pending             0          1h
kube-system   dummy-2088944543-j0cjx                  1/1       Running             1          1d
kube-system   etcd-kubemaster-01                      1/1       Running             1          1d
kube-system   kube-apiserver-kubemaster-01            1/1       Running             1          1d
kube-system   kube-controller-manager-kubemaster-01   1/1       Running             1          1d
kube-system   kube-discovery-1769846148-vps28         1/1       Running             1          1d
kube-system   kube-dns-2924299975-186b4               0/4       ContainerCreating   0          1d
kube-system   kube-proxy-0cqzn                        1/1       Running             1          1d
kube-system   kube-proxy-3dnvc                        1/1       Running             1          1d
kube-system   kube-scheduler-kubemaster-01            1/1       Running             1          1d
```
