# Jenkins

This documents demonstrates the deployment of Jenkins as a pod in a Kubernetes Cluster. The user can spawn a Jenkins deployment that will use OpenEBS as its persistent storage.

## Deploy as a Pod

Deploying Jenkins as a pod provides the following benefits:

- Isolates different jobs from one another.
- Quickly clean a job’s workspace.
- Dynamically deploy or schedule jobs with Kubernetes pods.
- Allows increased resource utilization and efficiency.

## Deploy Jenkins Pod with Persistent Storage

Before getting started check the status of the cluster:

```bash
ubuntu@kubemaster:~kubectl get nodes
NAME            STATUS    AGE       VERSION
kubemaster      Ready     3d        v1.7.5
kubeminion-01   Ready     3d        v1.7.5
kubeminion-02   Ready     3d        v1.7.5

```

Download and apply the Jenkins YAML from OpenEBS repo:

```bash
ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/jenkins/jenkins.yml

ubuntu@kubemaster:~kubectl apply -f jenkins.yml
```

Get the status of running pods:

```bash
ubuntu@kubemaster:~kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
jenkins-2748455067-85jv2                                         1/1       Running   0          9m
maya-apiserver-3416621614-r4821                                  1/1       Running   0          17m
openebs-provisioner-4230626287-7kjt4                             1/1       Running   0          17m
pvc-c52aa2d0-bcbc-11e7-a3ad-021c6f7dbe9d-ctrl-1457148150-v6ccz   1/1       Running   0          9m
pvc-c52aa2d0-bcbc-11e7-a3ad-021c6f7dbe9d-rep-2977732037-kqv6f    1/1       Running   0          9m
pvc-c52aa2d0-bcbc-11e7-a3ad-021c6f7dbe9d-rep-2977732037-s6g2s    1/1       Running   0          9m

```

Get the status of underlying persistent volume being used by Jenkins deployment:

```bash
ubuntu@kubemaster:~kubectl get pvc
NAME            STATUS    VOLUME                                     CAPACITY   ACCESSMODES   STORAGECLASS       AGE
jenkins-claim   Bound     pvc-c52aa2d0-bcbc-11e7-a3ad-021c6f7dbe9d   5G         RWO           openebs-standard   12m

```

Get the status of jenkins service:

```bash
ubuntu@kubemaster:~kubectl get svc
NAME                                                CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
jenkins-svc                                         10.107.147.241   <nodes>       80:32540/TCP        25m
kubernetes                                          10.96.0.1        <none>        443/TCP             3d
maya-apiserver-service                              10.97.14.255     <none>        5656/TCP            33m
pvc-c52aa2d0-bcbc-11e7-a3ad-021c6f7dbe9d-ctrl-svc   10.110.186.186   <none>        3260/TCP,9501/TCP   25m

```

## Launch Jenkins

The Jenkins deployment YAML, creates a service of type NodePort to make Jenkins available outside the cluster.

Get the IP Address of the node running the Jenkins pod:

```bash
ubuntu@kubemaster:~kubectl describe pod jenkins-2748455067-85jv2 | grep Node:
Node:		kubeminion-02/172.28.128.5

```
Get the port number from the Jenkins service:

```bash
ubuntu@kubemaster-01:~ kubectl describe svc jenkins-svc | grep NodePort:
NodePort:		<unset>	32540/TCP

```

Open the below URL in the browser:

```bash
https://172.28.128.5:32540

```

_Note: The NodePort is dynamically allocated and may vary in a different deployment._

__Provide the _initialAdminPassword___

![Jenkins Login]

Get the password using the below command:

```bash
ubuntu@kubemaster:~kubectl exec -it jenkins-2748455067-85jv2 cat /var/jenkins_home/secrets/initialAdminPassword
7d7aaedb5a2a441b99117b3bb55c1eff
```

__Install the Suggested Plugins__

![Jenkins Plugins]

__Configure the Admin User__

![Configure User]

__Start Using Jenkins__

![Jenkins Dashboard]

[Jenkins Login]: images/jenkins_login.png
[Jenkins Plugins]: images/jenkins_plugins.png
[Configure User]: images/jenkins_create_user.png
[Jenkins Dashboard]: images/jenkins_dashboard.png