# UPGRADE FROM OPENEBS 0.4.0 TO 0.5.0

- *OpenEBS Operator : Refers to maya-apiserver & openebs-provisioner along w/ respective services, service a/c, roles, rolebindings*
- *OpenEBS Volume: The Jiva controller & replica pods*
- *All steps described in this document need to be performed on the Kubernetes master*
- *The same steps can be used to upgrade OpenEBS from 0.4.0 to 0.5.1* 

### STEP-1 : CORDON ALL NODES WHICH DO NOT HOST OPENEBS VOLUME REPLICAS 

Perform ```kubectl cordon <node>``` on all nodes that don't have the openebs volume replicas

**Notes** : This is to ensure that the replicas are not rescheduled elsewhere(other nodes) upon upgrade and "stick" to the same 
nodes. This is done to maintain data gravity, as we keep the data on the host disks and prefer to avoid multiple full-copies/sync 
of the data on newer nodes.Subsequent releases will have logic to ensure the replicas come up on same nodes w/o having to ensure 
the same manually.

### STEP-2 : OBTAIN YAML SPECIFICATIONS FROM OPENEBS 0.5.0 RELEASE

Obtain the specifications from https://github.com/openebs/openebs/releases/tag/v0.5.0 

### STEP-3: UPGRADE TO THE 0.5.0 OPENEBS OPERATOR

```
test@Master:~$ kubectl apply -f k8s/openebs-operator.yaml
serviceaccount "openebs-maya-operator" configured
clusterrole "openebs-maya-operator" configured
clusterrolebinding "openebs-maya-operator" configured
deployment "maya-apiserver" configured
service "maya-apiserver-service" configured
deployment "openebs-provisioner" configured
customresourcedefinition "storagepoolclaims.openebs.io" created
customresourcedefinition "storagepools.openebs.io" created
storageclass "openebs-standard" created
```

**Notes** : This step will upgrade the operator deployments with the 0.5.0 images, and also :

- Sets up the pre-requisites for volume monitoring
- Creates a new OpenEBS storage-class called openebs-standard with : vol-size=5G, storage-replica-count=2, storagepool=default, monitoring=True
  
The above storage-class template can be used to create new ones with desired properties

### STEP-4: CREATE THE OPENEBS MONITORING DEPLOYMENTS (Prometheus & Grafana)

While this is an optional step, it is recommended to use the monitoring framework to track storage metrics on the OpenEBS 
volume.

```
testk@Master:~$ kubectl apply -f k8s/openebs-monitoring-pg.yaml
configmap "openebs-prometheus-tunables" created
configmap "openebs-prometheus-config" created
deployment "openebs-prometheus" created
service "openebs-prometheus-service" created
service "openebs-grafana" created
deployment "openebs-grafana" created

Verify that the monitoring pods are created & the operator pods are in running state. Together these constitute
the OpenEBS control plane in 0.5.0

test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
maya-apiserver-2288016177-lzctj                                  1/1       Running   0          1m
openebs-grafana-2789105701-0rw6v                                 1/1       Running   0          14s
openebs-prometheus-4109589487-4bngb                              1/1       Running   0          14s
openebs-provisioner-2835097941-5fcxh                             1/1       Running   0          1m
percona-2503451898-5k9xw                                         1/1       Running   0          7m
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-ctrl-3477661062-t0pg9   1/1       Running   0          7m
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-rep-3163680705-4d7x2    1/1       Running   0          7m
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-rep-3163680705-lbgpc    1/1       Running   0          7m

test@Master:~$ kubectl get svc
NAME                                                CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
kubernetes                                          10.96.0.1        <none>        443/TCP             24h
maya-apiserver-service                              10.102.159.226   <none>        5656/TCP            9m
openebs-grafana                                     10.101.147.181   <nodes>       3000:32515/TCP      45s
openebs-prometheus-service                          10.106.180.138   <nodes>       80:32514/TCP        45s
percona-mysql                                       10.100.189.43    <none>        3306/TCP            7m
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-ctrl-svc   10.111.2.96      <none>        3260/TCP,9501/TCP   7m

**Notes** : This also creates a default prometheus configmap which can be upgraded if needed. The prometheus 
and grafana services are available on the node ports at ports 32514 & 32515 respectively

```
### STEP-5: UPDATE OPENEBS VOLUME (CONTROLLER AND REPLICA) DEPLOYMENTS 

Obtain the name of the OpenEBS PersistentVolume (PV) that has to be updated

```
test@Master:~$ kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS    CLAIM                     STORAGECLASS       REASON    AGE
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc   5G         RWO            Delete           Bound     default/demo-vol1-claim   openebs-basic    
```

Run the script oebs_update.sh by passing the PV as argument

```
test@Master:~$ ./oebs_update pvc-01174ced-0a40-11e8-be1c-000c298ff5fc
deployment "pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-rep" patched
deployment "pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-ctrl" patched
replicaset "pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-ctrl-59df76689f" deleted
```
**Notes** : This script replaces the replica and controller patch files with the appropriate container names derived from the 
PV and patches the volume deployments using the ```kubectl patch deployment``` command. 
In each case, it verifies whether the new images have been rolled out successfully, using ```kubectl rollout status deployment```
before proceeding to the next step. Post patching, it also deletes the orphaned replicaset of the controller deployment as a 
workaround for this issue : https://github.com/openebs/openebs/issues/1201


Verify that the volume controller and replica pods are running post upgrade 

```
test@Master:~$ kubectl get pods
NAME                                                             READY     STATUS    RESTARTS   AGE
maya-apiserver-2288016177-lzctj                                  1/1       Running   0          3m
openebs-grafana-2789105701-0rw6v                                 1/1       Running   0          2m
openebs-prometheus-4109589487-4bngb                              1/1       Running   0          2m
openebs-provisioner-2835097941-5fcxh                             1/1       Running   0          3m
percona-2503451898-5k9xw                                         1/1       Running   0          9m
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-ctrl-6489864889-ml2zw   2/2       Running   0          10s
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-rep-6b9f46bc6b-4vjkf    1/1       Running   0          20s
pvc-8cc9c06c-ea22-11e7-9112-000c298ff5fc-rep-6b9f46bc6b-hvc8b    1/1       Running   0          20s
```

### STEP-6: VERIFY THAT ALL THE REPLICAS ARE REGISTERED AND ARE IN RW MODE

Execute the following REST query by providing the controller pod IP or service IP to obtain replica status 

**Notes** : 

- Get the pod/service IP by kubectl get pods -o wide/kubectl get svc respectively
- Install jq package on the kubernetes node/master where the following command is executed

```
test@Master:~$ curl GET http://10.47.0.5:9501/v1/replicas | grep createTypes | jq
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   162  100   162    0     0     27      0  0:00:06  0:00:05  0:00:01    37
100   971  100   971    0     0   419k      0 --:--:-- --:--:-- --:--:--  419k
{
  "createTypes": {
    "replica": "http://10.47.0.5:9501/v1/replicas"
  },
  "data": [
    {
      "actions": {
        "preparerebuild": "http://10.47.0.5:9501/v1/replicas/dGNwOi8vMTAuNDcuMC4zOjk1MDI=?action=preparerebuild",
        "verifyrebuild": "http://10.47.0.5:9501/v1/replicas/dGNwOi8vMTAuNDcuMC4zOjk1MDI=?action=verifyrebuild"
      },
      "address": "tcp://10.47.0.3:9502",
      "id": "dGNwOi8vMTAuNDcuMC4zOjk1MDI=",
      "links": {
        "self": "http://10.47.0.5:9501/v1/replicas/dGNwOi8vMTAuNDcuMC4zOjk1MDI="
      },
      "mode": "RW",
      "type": "replica"
    },
    {
      "actions": {
        "preparerebuild": "http://10.47.0.5:9501/v1/replicas/dGNwOi8vMTAuNDQuMC41Ojk1MDI=?action=preparerebuild",
        "verifyrebuild": "http://10.47.0.5:9501/v1/replicas/dGNwOi8vMTAuNDQuMC41Ojk1MDI=?action=verifyrebuild"
      },
      "address": "tcp://10.44.0.5:9502",
      "id": "dGNwOi8vMTAuNDQuMC41Ojk1MDI=",
      "links": {
        "self": "http://10.47.0.5:9501/v1/replicas/dGNwOi8vMTAuNDQuMC41Ojk1MDI="
      },
      "mode": "RW",
      "type": "replica"
    }
  ],
  "links": {
    "self": "http://10.47.0.5:9501/v1/replicas"
  },
  "resourceType": "replica",
  "type": "collection"
}
```

### STEP-7: CONFIGURE GRAFANA TO MONITOR VOLUME METRICS

Perform the following actions if Step-4 was executed. 

- Access the grafana dashboard at `http://*NodeIP*:32515`
- Add the prometheus data source by giving URL as `http://*NodeIP*:32514`
- Once data source is validated, import the dashboard JSON from : 
  https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-pg-dashboard.json
- Access the volume stats by selecting the volume name (pvc-*) in the OpenEBS Volume dashboard

**Note** : For new applications select a newly created storage-class that has monitoring enabled to automatically start viewing metrics
