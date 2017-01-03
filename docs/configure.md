#Storage Configuration 


Download the Sample Configuration 

```
ubuntu@master-01:~$ mkdir vsms
ubuntu@master-01:~$ cd vsms/
ubuntu@master-01:~/vsms$ wget https://raw.githubusercontent.com/openebs/maya/master/demo/jobs/demo-vsm1.hcl
```


Modify the IP address on which the iSCSI volumes needs to be accessed by the frontend container. Provide the size and an unique name. 

```
        meta {
                JIVA_VOLNAME = "demo1-vsm1-vol1"
                JIVA_VOLSIZE = "10g"
                JIVA_FRONTENDIP = "172.28.128.101"
        }

```

Customize the frontend container parameters like the subnet mask, network interface or the version of the jiva to launch. 

```
                # Define the controller task to run
                task "ctl" {
                        env {
                                JIVA_CTL_NAME = "${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}"
                                JIVA_CTL_VERSION = "openebs/jiva:latest"
                                JIVA_CTL_VOLNAME = "${NOMAD_META_JIVA_VOLNAME}"
                                JIVA_CTL_VOLSIZE = "${NOMAD_META_JIVA_VOLSIZE}"
                                JIVA_CTL_IP = "${NOMAD_META_JIVA_FRONTENDIP}"
                                JIVA_CTL_SUBNET = "24"
                                JIVA_CTL_IFACE = "enp0s8"
                        }
```

Similarly, customise the backend container pamameters:

```
                # Define the controller task to run
                task "rep-store1" {
                        env {
                                JIVA_REP_NAME = "${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}"
                                JIVA_REP_VERSION = "openebs/jiva:latest"
                                JIVA_CTL_IP = "${NOMAD_META_JIVA_FRONTENDIP}"
                                JIVA_REP_VOLNAME = "${NOMAD_META_JIVA_VOLNAME}"
                                JIVA_REP_VOLSIZE = "${NOMAD_META_JIVA_VOLSIZE}"
                                JIVA_REP_IP = "172.28.128.102"
                                JIVA_REP_SUBNET = "24"
                                JIVA_REP_IFACE = "enp0s8"
                                JIVA_REP_VOLSTORE = "/tmp/jiva/vsm1/rep1"
                        }
```


Schedule the VSM Creation 

```
ubuntu@master-01:~/vsms$ maya vsm-create demo-vsm1.hcl 
==> Monitoring evaluation "fdcc3770"
    Evaluation triggered by job "demo-vsm1"
    Allocation "01752980" created: node "cbceb3d2", group "demo-vsm1-ctl"
    Allocation "8ac55ddd" created: node "dc7fd9b9", group "rep-store2"
    Allocation "97065884" created: node "cbceb3d2", group "rep-store1"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "fdcc3770" finished with status "complete"
ubuntu@master-01:~/vsms$ 
```

Check the status

```
ubuntu@master-01:~/vsms$ maya vsm-list demo-vsm1
ID          = demo-vsm1
Name        = demo-vsm1
Type        = service
Priority    = 50
Datacenters = dc1
Status      = running
Periodic    = false

Summary
Task Group     Queued  Starting  Running  Failed  Complete  Lost
demo-vsm1-ctl  0       0         1        0       0         0
rep-store1     0       0         1        0       0         0
rep-store2     0       0         1        0       0         0

Allocations
ID        Eval ID   Node ID   Task Group     Desired  Status   Created At
01752980  fdcc3770  cbceb3d2  demo-vsm1-ctl  run      running  01/03/17 13:10:14 UTC
8ac55ddd  fdcc3770  dc7fd9b9  rep-store2     run      running  01/03/17 13:10:14 UTC
97065884  fdcc3770  cbceb3d2  rep-store1     run      running  01/03/17 13:10:14 UTC
ubuntu@master-01:~/vsms$ 
```

Check the osh where the VSMs are running. 

```
ubuntu@master-01:~$ maya osh-status
ID        DC   Name     Class   Drain  Status
cbceb3d2  dc1  host-02  <none>  false  ready
dc7fd9b9  dc1  host-01  <none>  false  ready
ubuntu@master-01:~$ 
```


Docker status

```
ubuntu@host-02:~$ docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
openebs/jiva        latest              d3e3835763f3        11 days ago         308 MB
ubuntu@host-02:~$ docker ps
CONTAINER ID        IMAGE                 COMMAND                  CREATED             STATUS              PORTS               NAMES
2427c7a510bb        openebs/jiva:latest   "launch controller --"   57 seconds ago      Up 51 seconds                           demo-vsm1-ctl
c01ce8d57dd8        openebs/jiva:latest   "launch replica --fro"   57 seconds ago      Up 51 seconds                           demo-vsm1-rep-store1
ubuntu@host-02:~$ 
```
