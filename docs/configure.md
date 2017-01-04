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
                JIVA_VOLNAME = "demo-vsm1-vol1"
                JIVA_VOLSIZE = "10g"
                JIVA_FRONTEND_VERSION = "openebs/jiva:latest"
                JIVA_FRONTEND_NETWORK = "host_static"
                JIVA_FRONTENDIP = "172.28.128.101"
                JIVA_FRONTENDSUBNET = "24"
                JIVA_FRONTENDINTERFACE = "enp0s8"
        }

```

Similarly, customise the backend container pamameters:

```                        
                        env {
                                JIVA_REP_NAME = "${NOMAD_JOB_NAME}-${NOMAD_TASK_NAME}"
                                JIVA_CTL_IP = "${NOMAD_META_JIVA_FRONTENDIP}"
                                JIVA_REP_VOLNAME = "${NOMAD_META_JIVA_VOLNAME}"
                                JIVA_REP_VOLSIZE = "${NOMAD_META_JIVA_VOLSIZE}"
                                JIVA_REP_VOLSTORE = "/tmp/jiva/vsm1/rep1"
                                JIVA_REP_VERSION = "openebs/jiva:latest"
                                JIVA_REP_NETWORK = "host_static"
                                JIVA_REP_IFACE = "enp0s8"
                                JIVA_REP_IP = "172.28.128.102"
                                JIVA_REP_SUBNET = "24"
                        }
```


Schedule the VSM Creation 

```
ubuntu@master-01:~/vsms$ maya vsm-create demo-vsm1.hcl 
==> Monitoring evaluation "f8917fad"
    Evaluation triggered by job "demo-vsm1"
    Allocation "59ecd70d" created: node "1baf7f69", group "demo-vsm1-backend-container1"
    Allocation "d10ff4fc" created: node "b779de4d", group "demo-vsm1-fe"
    Allocation "d196cfb3" created: node "1baf7f69", group "demo-vsm1-backend-container2"
    Evaluation status changed: "pending" -> "complete"
==> Evaluation "f8917fad" finished with status "complete"

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
Task Group                    Queued  Starting  Running  Failed  Complete  Lost
demo-vsm1-backend-container1  0       0         1        0       0         0
demo-vsm1-backend-container2  0       0         1        0       0         0
demo-vsm1-fe                  0       0         1        0       0         0

Allocations
ID        Eval ID   Node ID   Task Group                    Desired  Status   Created At
59ecd70d  f8917fad  1baf7f69  demo-vsm1-backend-container1  run      running  01/04/17 07:39:33 UTC
d10ff4fc  f8917fad  b779de4d  demo-vsm1-fe                  run      running  01/04/17 07:39:33 UTC
d196cfb3  f8917fad  1baf7f69  demo-vsm1-backend-container2  run      running  01/04/17 07:39:33 UTC
ubuntu@master-01:~/vsms$ 

```

Check the osh where the VSMs are running. 

```
ubuntu@master-01:~/vsms$ maya osh-status
ID        DC   Name     Class   Drain  Status
1baf7f69  dc1  host-02  <none>  false  ready
b779de4d  dc1  host-01  <none>  false  ready
ubuntu@master-01:~/vsms$ 

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
