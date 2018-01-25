
Couchbase Server
==================
 
This section demonstrates the Couchbase deployment as a StatefulSet in a Kubernetes cluster. You can spawn a Couchbase StatefulSet that will use OpenEBS as its persistent storage.

Deploying Couchbase as a StatefulSet
--------------------------------------
Deploying Couchbase as a StatefulSet provides the following benefits.

* Stable unique network identifiers
* Stable persistent storage
* Ordered graceful deployment and scaling
* Ordered graceful deletion and termination

Deploying Couchbase with Persistent Storage
----------------------------------------------
Before getting started, check the status of the cluster using the following command.
::

    ubuntu@kubemaster:~kubectl get nodes
    NAME            STATUS    AGE       VERSION
    kubemaster      Ready     3d        v1.8.2
    kubeminion-01   Ready     3d        v1.8.2
    kubeminion-02   Ready     3d        v1.8.2

Download and apply the Couchbase YAML from OpenEBS repository using the following command.
::

    ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/couchbase/couchbase-statefulset.yml
    ubuntu@kubemaster:~wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/demo/couchbase/couchbase-service.yml


    ubuntu@kubemaster:~kubectl apply -f couchbase-statefulset.yml
    ubuntu@kubemaster:~kubectl apply -f couchbase-service.yml

Get the status of running pods using the following command.
::

    ubuntu@kubemaster:~$ kubectl get pods --all-namespaces
    NAMESPACE     NAME                                                             READY     STATUS    RESTARTS   AGE
    default       couchbase-0                                                      1/1       Running   0          11h
    default       couchbase-1                                                      1/1       Running   0          11h
    default       maya-apiserver-6fc5b4d59c-mg9k2                                  1/1       Running   0          3d
    default       openebs-provisioner-6d9b78696d-h647b                             1/1       Running   0          3d
    default       pvc-16210b06-c7ba-11e7-892e-000c29119159-ctrl-78db5f845b-v7w5s   1/1       Running   0          11h
    default       pvc-16210b06-c7ba-11e7-892e-000c29119159-rep-94d9844df-78zsm     1/1       Running   0          11h
    default       pvc-16210b06-c7ba-11e7-892e-000c29119159-rep-94d9844df-rh4xs     1/1       Running   0          11h
    default       pvc-40e1b64f-c7ba-11e7-892e-000c29119159-ctrl-c54b6969b-75mjj    1/1       Running   0          11h
    default       pvc-40e1b64f-c7ba-11e7-892e-000c29119159-rep-6cd4655d87-6rgvm    1/1       Running   0          11h
    default       pvc-40e1b64f-c7ba-11e7-892e-000c29119159-rep-6cd4655d87-h7w9x    1/1       Running   0          11h
    kube-system   etcd-o-master01                                                  1/1       Running   0          3d
    kube-system   kube-apiserver-o-master01                                        1/1       Running   0          3d
    kube-system   kube-controller-manager-o-master01                               1/1       Running   0          3d
    kube-system   kube-dns-545bc4bfd4-m4ngc                                        3/3       Running   0          3d
    kube-system   kube-proxy-4ml5l                                                 1/1       Running   0          3d
    kube-system   kube-proxy-7jlpf                                                 1/1       Running   0          3d
    kube-system   kube-proxy-cxkpc                                                 1/1       Running   0          3d
    kube-system   kube-scheduler-o-master01                                        1/1       Running   0          3d
    kube-system   weave-net-ctfk4                                                  2/2       Running   0          3d
    kube-system   weave-net-dwszp                                                  2/2       Running   0          3d
    kube-system   weave-net-pzbb7          

Get the status of running StatefulSets using the following command.
::

    ubuntu@kubemaster:~$ kubectl get statefulset
    NAME        DESIRED   CURRENT   AGE
    couchbase   2         2         11h

Get the status of underlying persistent volume used by Couchbase StatefulSet using the following command.
::

    ubuntu@kubemaster:~$ kubectl get pvc
    NAME                         STATUS    VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS       AGE
    couchbase-data-couchbase-0   Bound     pvc-16210b06-c7ba-11e7-892e-000c29119159   5G         RWO            openebs-standard   11h
    couchbase-data-couchbase-1   Bound     pvc-40e1b64f-c7ba-11e7-892e-000c29119159   5G         RWO            openebs-standard   11h

Get the status of the services using the following command.
::

    ubuntu@kubemaster:~kubectl get svc
    ME                                                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
    couchbase                                           ClusterIP   None             <none>        8091/TCP            11h
    couchbase-ui                                        NodePort    10.103.161.153   <none>        8091:30438/TCP      11h
    kubernetes                                          ClusterIP   10.96.0.1        <none>        443/TCP             3d
    maya-apiserver-service                              ClusterIP   10.111.26.252    <none>        5656/TCP            3d

Launching Couchbase as a Server
---------------------------------
The Couchbase service YAML, creates a NodePort service type for making the Couchbase server available outside the cluster.

Get the node's IP Address which is running the Couchbase server using the following command.
::

    ubuntu@kubemaster:~kubectl describe pod couchbase-0 | grep Node:
    Node:		kubeminion-02/20.10.29.203

Get the port number from the Couchbase UI service using the following command.
::

    ubuntu@kubemaster:~ kubectl describe svc couchbase-ui | grep NodePort:
    NodePort:		couchbase  30438/TCP

Go to the https://20.10.29.203:30438 URL from your browser and perform the following procedure from the UI.

**Note:**

* For Google Cloud Users, create Firewall Rules to perform tasks using Couchbase UI.
* The NodePort is dynamically allocated and may vary in a different deployment. 

1. In the Couchbase Console, enter your credentials in the **Username** and **Password** fields and click **Sign In**. You can now see the console.[The default Username is Administrator and Password is password. Enter the credentials to see the console.]
2. Click **Server Nodes** to see the number of Couchbase nodes that are part of the cluster. As expected, it displays only one node.
3. Click **Data Buckets** to see a sample bucket that was created as part of the image.

You can now start using Couchbase.

