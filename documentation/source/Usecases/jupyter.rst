
Jupyter
=========
Running Jupyter on OpenEBS
---------------------------

This section provides detailed instructions on how to run a jupyter pod on OpenEBS storage in a Kubernetes cluster and uses a *jupyter ui editor* to generate load in order to illustrate input/output traffic on the storage.

Run Jupyter Pod with OpenEBS Storage
--------------------------------------
Use OpenEBS as persistent storage for the jupyter pod by selecting an OpenEBS storage class in the persistent volume claim. A sample jupyter pod yaml (with container attributes and pvc details) is available in the OpenEBS git repository (which was cloned in the previous steps).
::
   name@Master:~$ cat demo-jupyter-openebs.yaml
   ..
   kind: PersistentVolumeClaim
   apiVersion: v1
   metadata:
     name: jupyter-data-vol-claim
   spec:
     storageClassName: openebs-jupyter
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 5G
    ..

Apply the jupyter pod yaml using the following command.

::

   name@Master:~$ kubectl apply -f demo-jupyter-openebs.yaml
   deployment "jupyter-server" created
   persistentvolumeclaim "jupyter-data-vol-claim" created
   service "jupyter-service" created

The above command creates the following, which can be verified using the corresponding kubectl commands.

- Launches a Jupyter Server, with the specified notebook file from github (kubectl get deployments)
- Creates an OpenEBS Volume and mounts to the Jupyter Server Pod (/mnt/data) (kubectl get pvc) (kubectl get pv) (kubectl get pods)
- Exposes the Jupyter Server to external world via the http://<NodeIP>:32424 (NodeIP is any of the nodes external IP) (kubectl get pods)   

Verify that the OpenEBS storage pods, that is, the jiva controller and jiva replicas are created and the jupyter pod is running successfully using the following commands.

::
 
   name@Master:~$ kubectl get pods
   NAME                                                             READY     STATUS    RESTARTS   AGE
   jupyter-server-2764185079-s371g                                  1/1       Running   0          13m
   maya-apiserver-1633167387-845fd                                  1/1       Running   0          15d
   openebs-provisioner-1174174075-c78sj                             1/1       Running   1          15d
   pvc-5467cfe7-a29e-11e7-b4df-000c298ff5fc-ctrl-2903536303-75h3j   1/1       Running   0          13m
   pvc-5467cfe7-a29e-11e7-b4df-000c298ff5fc-rep-2383373508-bh0d3    1/1       Running   0          13m
   pvc-5467cfe7-a29e-11e7-b4df-000c298ff5fc-rep-2383373508-s1kzz    1/1       Running   0          13m

**Note:**

It may take some time for the pods to start as the images must be pulled and instantiated. This is also dependent on the network speed.

The jupyter server dashboard can be accessed on the Kubernetes node port as in the following screen.

.. image:: https://raw.githubusercontent.com/openebs/openebs/master/documentation/source/_static/Jupyter.png