This document will help to delete the auto-generated snapshots created during Jiva replica restart or when a new replica is added to the Jiva controller. The steps for deleting the auto-generated snapshots are as follows:

Get the details of Jiva controller pod using the following command. It will show the Jiva pods details running in `default` namespace. 

```
kubectl get pod -n default
```
Example output:
```
NAME                                                            READY   STATUS    RESTARTS   AGE
percona-7b64956695-kd9q4                                        1/1     Running   0          105s
pvc-d01e90d9-a921-11e9-93c2-42010a8000ab-ctrl-df9c749cf-jp6mg   2/2     Running   0          104s
pvc-d01e90d9-a921-11e9-93c2-42010a8000ab-rep-795d8c5cb8-4wb9c   1/1     Running   0          101s
pvc-d01e90d9-a921-11e9-93c2-42010a8000ab-rep-795d8c5cb8-gfxg9   1/1     Running   0          101s
pvc-d01e90d9-a921-11e9-93c2-42010a8000ab-rep-795d8c5cb8-n4cfq   1/1     Running   1          101s
```

List all internal snapshots created inside corresponding Jiva controller using the following command.
```
kubectl exec -it <jiva_controller_pod> -n <namespace> jivactl snapshot ls
```

For Example:
```
kubectl exec -it pvc-d01e90d9-a921-11e9-93c2-42010a8000ab-ctrl-df9c749cf-jp6mg -n default jivactl snapshot ls
```

Example output:
```
ID
f1b68e2a-5a3d-4737-85d0-b34c1452db7c
1e5441ff-ec75-4618-a5f0-d5de25eca1b2
4ec87701-6faf-4c72-816b-d81885c67263
02617eeb-2147-4adf-8e6b-0317c7fad79d
fb1bac27-bd46-41be-831a-12ebe5421d23
c4556aff-6da2-4fb3-ba8c-a0d7bfad67bb
1bb0cf11-1a6c-45d4-8638-daac561baf0d
b9261581-6713-45cb-a87f-bafefa2fd6ee
c80150ac-f3c2-4c3a-a289-138a80dc4e0d
ef478c62-22da-4045-abaf-7f08b68c5696
bf4e562b-61e4-4bbf-87cc-7026e4b7bb7f
9f40b8df-2641-4502-b451-979c97e73392
53cf1bbe-a2a1-430a-bd20-50528fed6a32
c61e9c1f-64d2-48f0-866e-a9cc1820bf7a
d969a089-e125-4189-a5e8-922c9f5fd48b
529ea5b9-2b03-4524-91e0-fda623365e88
cb8fd2da-c132-487f-85c9-5ac5189a5cda
cd0a5074-be77-4e3b-b141-e91a6fba94d3
277aacdb-3f24-4203-8206-d871294a9292
4231e0aa-65ea-4f86-81e5-db29930b61b7
```

Now exit from the container using `exit` command.

Download the files for deleting Jiva snapshots from Jiva repository using the following commands.
```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/jiva/patch.json
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/jiva/snapshot-cleanup.sh
```
Ensure that `snapshot-cleanup.sh` has execute permission. If not, make it executable by running `chmod +x snapshot-cleanup.sh` from the  downloaded folder.

Now get the PV name using the following command.
```
kubectl get pv | grep <PVC_name>
```
Example:
```
kubectl get pv | grep demo-vol1-claim
```

Example Output:
```
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                     STORAGECLASS           REASON   AGE
pvc-d01e90d9-a921-11e9-93c2-42010a8000ab   5G         RWO            Delete           Bound    default/demo-vol1-claim   openebs-jiva-default            10m
```

The following script will execute when number of Jiva auto-generated snapshots are more than 5. Else, it will exit. This means, minimum available snapshot will be always more than 5. For example, if total number of Jiva auto-generated snapshots are 20 and required number of snapshot to be deleted is 15, then this script will not work. In this case, the script will work if you give 14 instead of 15 as the number of snapshots to be deleted.

**Note:**

Snapshot cleanup process involves disconnecting the application from its storage. Ensure that the application is not being used and the connectivity to the Kubernetes Cluster is active while performing the snapshot cleanup process. To ensure that the application is not connected to the storage, it is recommended to scale down the application.

Delete the auto-generated internal snapshots using the following command.

```
./ snapshot-cleanup.sh <pv-name> <number_of_snapshots_to_delete>
```

Example:

```
./snapshot-cleanup.sh pvc-d01e90d9-a921-11e9-93c2-42010a8000ab 12
```

In the above example, 12 snapshots will be deleted from the total number of the auto-generated snapshots of the volume. After deleting mentioned number of snapshots, total number of auto generated snapshot will be (old total number- given number for deletion) + (total number of replica -1). In this example, (21-12)+2=11

**Note:** In case of unexpected disconnect during the cleanup process, you will have to run the following command to restore the volume service.
```
./snapshot-cleanup.sh <pv-name> restore_service
```

You can use the steps described above to list the current snapshots available on jiva.
