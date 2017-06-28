This is place-holder for providing the steps to run clustered postgresql on K8s+OpenEBS. We hope to merge these files back to https://github.com/CrunchyData/crunchy-containers/blob/master/examples/kube/



## Usage

Once you have OpenEBS enabled on your K8s Cluster, you can use the following simple steps to launch a clustered postgresql service with one master and one replica. 

### Step 1: Download the files to your host, which has access to kubectl 
```
cd $HOME
git clone https://github.com/openebs/openebs.git
cd openebs/k8s/demo/crunchy-postgres
```

### Step 2: Run the StatefulSet. 
The files are make available with default images and credentails (set.json)
```
./run.sh
```

The above step will automatically create the OpenEBS volumes required for master and replica postgresql containers. The volume details can be inspected using the standard kubectl commands like:
```
kubectl get pvc
kubectl get pv
```


## Motivation

The k8s spec files are based on the files provided by [CrunchyData StatefulSet with Dynamic Provisioner](https://github.com/CrunchyData/crunchy-containers/tree/master/examples/kube/statefulset-dyn)

Kubernetes Blog for running [Clustered PostgreSQL using StatefulSet](http://blog.kubernetes.io/2017/02/postgresql-clusters-kubernetes-statefulsets.html)


