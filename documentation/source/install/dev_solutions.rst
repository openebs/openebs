********************
Developer Solutions
********************

Minikube
=========

Setting up OpenEBS with Kubernetes using Minikube
---------------------------------------------------

Minikube helps developers to quickly setup a single-node Kubernetes cluster for their development environment. There are several options available for developers to install Minikube. See, `Minikube Setup`_.

       .. _Minikube Setup: https://github.com/kubernetes/minikube

If you are already an experienced Minikube user, you can easily setup OpenEBS on your existing Kubernetes cluster with a few simple kubectl commands. See, :ref:`quick-start`.

This section provides instructions to set up Kubernetes using Minikube directly on Ubuntu 16.04 (without using any VM drivers) and to have OpenEBS running in hyperconverged mode. 

Prerequisites
---------------
Minimum requirements for using Minikube

* Machine Type - (Minimum 4 vCPUs)
* RAM - (Minimum 4 GB)

Make sure *docker* is installed on your Ubuntu host. 
 
Installing Docker on Ubuntu
-----------------------------

The following commands help you install Docker on Ubuntu version 16.04 (64 bit).
::

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    apt-cache policy docker-ce
    sudo apt-get install -y docker-ce 
 
Add iSCSI Support
-------------------

On your Ubuntu host, install open-iscsi package. OpenEBS uses iSCSI to connect to the block volumes.
::
    
    sudo apt-get update
    sudo apt-get install open-iscsi
    sudo service open-iscsi restart

Verify that iSCSI is configured
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check that initiator name is configured and iSCSI service is running using the following commands.
::

   sudo cat /etc/iscsi/initiatorname.iscsi
   sudo service open-iscsi status


Download and setup Minikube and kubectl
-----------------------------------------

On your Ubuntu host, install minikube.
::

    curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    chmod +x minikube 
    sudo mv minikube /usr/local/bin/

On your Ubuntu host, install kubectl.
::

    curl -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
    chmod +x kubectl 
    sudo mv kubectl /usr/local/bin/

On your Ubuntu host, setup directories for storing minkube and kubectl configuration.
::

    mkdir $HOME/.kube || true
    touch $HOME/.kube/config

On your Ubuntu host, setup the environment for minikube. Copy the following to ~/.profile.
::

    export MINIKUBE_WANTUPDATENOTIFICATION=false
    export MINIKUBE_WANTREPORTERRORPROMPT=false
    export MINIKUBE_HOME=$HOME
    export CHANGE_MINIKUBE_NONE_USER=true
    export KUBECONFIG=$HOME/.kube/config

On your Ubuntu host, start minikube.
::

    sudo -E minikube start --vm-driver=none

Verify that minikube is configured
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check that minikube is configured and it has started using the following commands.
::

    minikube status

When minikube is configured properly, *minikube status* will display the following output:
::

   minikube: Running
   cluster: Running
   kubectl: Correctly Configured: pointing to minikube-vm at 127.0.0.1

**Note** 
  * If minikube status displays *Stopped*, add sudo minikube start command.
  * If minikube displays errors indicating permission denied to configuration files, fix the permissions by running the following commands.
::

    sudo chown -R $USER $HOME/.kube
    sudo chgrp -R $USER $HOME/.kube
    sudo chown -R $USER $HOME/.minikube
    sudo chgrp -R $USER $HOME/.minikube

Verify that Kubernetes is configured
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Check that kubectl is configured and services are running using the following commands.
::

    kubectl get pods
    kubectl get nodes

When configured properly, the above kubectl commands will display output similar to following:
::

    vagrant@minikube-dev:~$ kubectl get nodes
    NAME           STATUS    AGE       VERSION
    minikube-dev   Ready     8m        v1.7.5
    vagrant@minikube-dev:~$ kubectl get pods --all-namespaces
    NAMESPACE     NAME                              READY     STATUS    RESTARTS   AGE
    kube-system   kube-addon-manager-minikube-dev   1/1       Running   1          8m
    kube-system   kube-dns-910330662-4q4bm          3/3       Running   3          8m
    kube-system   kubernetes-dashboard-txn8f        1/1       Running   1          8m
    vagrant@minikube-dev:~$ 


Setup OpenEBS
-------------

Download the latest OpenEBS Operator files using the following commands.
::

   git clone https://github.com/openebs/openebs.git
   cd openebs/k8s
   kubectl apply -f openebs-operator.yaml

**Note** 
By default, OpenEBS launches OpenEBS Volumes with two replicas. To set one replica, as is the case with single-node Kubernetes cluster, specify the environment variable *OPENEBS_IO_JIVA_REPLICA_COUNT=1*. If your OpenEBS version is < 0.5.0 you should use `DEFAULT_REPLICA_COUNT` environment variable instead of `OPENEBS_IO_JIVA_REPLICA_COUNT`.

The following snippet of the openebs-operator.yaml -> maya-apiserver section shows that how you should update it:
::

    ---
    apiVersion: apps/v1beta1
    kind: Deployment
    metadata:
      name: maya-apiserver
      namespace: default
    spec:
      replicas: 1
      template:
        metadata:
          labels:
            name: maya-apiserver
        spec:
          serviceAccountName: openebs-maya-operator
          containers:
          - name: maya-apiserver
            imagePullPolicy: Always
            image: openebs/m-apiserver:0.3-RC4
            ports:
            - containerPort: 5656
            env:
            - name: OPENEBS_IO_JIVA_REPLICA_COUNT
              value: "1"
    ---

Add OpenEBS related storage classes, that can then be used by developers and applications using the following command.
::

    kubectl apply -f openebs-storageclasses.yaml

Running Stateful Applications with OpenEBS Storage
----------------------------------------------------

To use OpenEBS as persistent storage for your stateful workloads, set the storage class in the Persistent Volume Claim (PVC) of your application to one of the OpenEBS storage class.

Get the list of storage classes using the following command. Choose the storage class that best suits your application.
::

    kubectl get sc

Some sample YAML files for stateful workloads using OpenEBS are provided in the `openebs/k8s/demo`_
        
  .. _openebs/k8s/demo: https://github.com/openebs/openebs/tree/master/k8s/demo

