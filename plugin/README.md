# Kubectl Plugin

## Overview
The kubectl plugin has been created in accordance with the instructions outlined in the [official documentation](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/).

This plugin simplifies storage management for OpenEBS users who have deployed their clusters using the OpenEBS umbrella chart. It provides a unified interface for all OpenEBS storage engines like Mayastor, LocalPV-LVM, LocalPV-ZFS, and LocalPV-HostPath.

This plugin leverages the existing ```kubectl mayastor``` codebase for Mayastor engine commands. For other engines (LocalPV-LVM, LocalPV-ZFS, and LocalPV-Hostpath), new code has been developed, drawing inspiration from the current ```kubectl openebs``` plugin.

While the original kubectl-openebs plugin only supported LocalPV engines, this plugin extends that support to include Mayastor and organizes commands by engine type for improved clarity and usability. Mayastor commands from `kubectl mayastor` are now available under the alias `kubectl openebs mayastor`.

## Namespace handling

This plugin avoids the hardcoded "mayastor" namespace assumption used by the ```kubectl-mayastor``` plugin. Instead, if a namespace is not explicitly provided, the plugin defaults to the namespace defined in the default kubeconfig context.The kubeconfig path is configurable using `--kube-config-path` or the `KUBECONFIG` env. Namespace can be set explicitly using the `--namespace` option.

This allows users to manage OpenEBS installations in any namespace. For example, if OpenEBS is installed in the "storage" namespace, users can set their current context's namespace using:

```
kubectl config set-context --namespace=storage --current
```

## Output format

By default output format for all command is Tabular. We also support JSON ```-o json``` and YAML ```-o yaml```

## Usage

**The plugin must be placed in your `PATH` in order for it to be used.**

The name of the plugin binary dictates how it is used. From the documentation:
> For example, a plugin named `kubectl-foo` provides a command `kubectl foo`.

In our case the name of the binary is specified in the Cargo.toml file as `kubectl-openebs`, therefore the command is `kubectl openebs`.

To make the plugin as intuitive as possible, every attempt has been made to make the usage as similar to that of the standard `kubectl` command line utility as possible.

The general command structure is `kubectl openebs <engine> <operation> <resource>` where engines can be any OpenEBS provided engine. The localpv engines have only `get` commands at the moment.
We can add more in future. Mayastor has addition operation support and the resource defines what the operation should be performed on (i.e. `volumes`, `pools`, `volume-groups`, `zpools` etc).

Here is the top-level help which includes global options:

```
Storage engines supported

Usage: kubectl-openebs [OPTIONS] <COMMAND>

Commands:
  mayastor          Mayastor operations
  localpv-lvm       LocalPV lvm operations
  localpv-zfs       LocalPV zfs operations
  localpv-hostpath  LocalPV Hostpath operations
  help              Print this message or the help of the given subcommand(s)

Options:
  -n, --namespace <NAMESPACE>  Namespace where openebs is installed. If unset, defaults to the default namespace in the current context
  -h, --help                   Print help
  -V, --version                Print version
  ```

## Global Options

Global options change depending on the storage engines in the command.

For all localpv engines haere is the global options, For ```localpv-lvm``` cmd for example:

```
Usage: kubectl-openebs localpv-lvm [OPTIONS] <COMMAND>

Commands:
  get   Gets localpv-lvm resources
  help  Print this message or the help of the given subcommand(s)

Options:
  -o, --output <OUTPUT>
          The Output, viz yaml, json [default: none]
  -n, --namespace <NAMESPACE>
          Namespace where openebs is installed. If unset, defaults to the default namespace in the current context
  -k, --kube-config-path <KUBE_CONFIG_PATH>
          Path to kubeconfig file
  -h, --help
          Print help                Print help
```

For Mayastor:

```
Options:
  -n, --namespace <NAMESPACE>
          Namespace where openebs is installed. If unset, defaults to the default namespace in the current context
  -r, --rest <REST>
          The rest endpoint to connect to
  -k, --kube-config-path <KUBE_CONFIG_PATH>
          Path to kubeconfig file
  -o, --output <OUTPUT>
          The Output, viz yaml, json [default: none]
  -j, --jaeger <JAEGER>
          Trace rest requests to the Jaeger endpoint agent
  -t, --timeout <TIMEOUT>
          Timeout for the REST operations [default: 10s]
  -h, --help
          Print help
```

### Examples and Outputs

### Mayastor

<details>
<summary> General Resources operations </summary>

1. Get Volumes
```
❯ kubectl openebs mayastor get volumes
 ID                                    REPLICAS  TARGET-NODE  ACCESSIBILITY  STATUS  SIZE   THIN-PROVISIONED  ALLOCATED  SNAPSHOTS  SOURCE
 18e30e83-b106-4e0d-9fb6-2b04e761e18a  4         kworker1     nvmf           Online  1GiB   true              8MiB       0          <none>
 ec4e66fd-3b33-4439-b504-d49aba53da26  1         <none>       <none>         Online  10MiB  true (snapped)    12MiB      1          <none>
 ec4e66fd-3b33-4439-b504-d49aba53da27  1         <none>       <none>         Online  10MiB  true              12MiB      0          Snapshot
 ec4e66fd-3b33-4439-b504-d49aba53da28  1         <none>       <none>         Online  10MiB  true              12MiB      0          Snapshot

```
2. Get Volume by ID
```
❯ kubectl openebs mayastor get volume 18e30e83-b106-4e0d-9fb6-2b04e761e18a
 ID                                    REPLICAS  TARGET-NODE  ACCESSIBILITY  STATUS  SIZE   THIN-PROVISIONED  ALLOCATED  SNAPSHOTS  SOURCE
 ec4e66fd-3b33-4439-b504-d49aba53da28  1         <none>       <none>         Online  10MiB  true              12MiB      0          Snapshot
 18e30e83-b106-4e0d-9fb6-2b04e761e18a  4         kworker1     nvmf           Online  1GiB   true              8MiB       0          <none>

```
3. Get Pools
```
❯ kubectl openebs mayastor get pools
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE
 pool-1-kworker1  aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker1  Online  500GiB    100GiB     400GiB
 pool-1-kworker2  aio:///dev/vdc?uuid=bb12ec7d-8fc3-4644-82cd-dee5b63fc8c5  true     kworker2  Online  500GiB    100GiB     400GiB
 pool-1-kworker3  aio:///dev/vdb?uuid=f324edb7-1aca-41ec-954a-9614527f77e1  true     kworker3  Online  500GiB    100GiB     400GiB
```
4. Get Pool by ID
```
❯ kubectl openebs mayastor get pool pool-1-kworker1
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE
 pool-1-kworker1  aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker1  Online  500GiB    100GiB     400GiB
```

5. Get Pool by Node ID
```
❯ kubectl openebs mayastor get pools --node kworker1
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE
 pool-1-kworker1  aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker1  Online  500GiB    100GiB     400GiB
 ```

6. Get Pool used by volume
```
❯ kubectl openebs mayastor get pools --volume ec4e66fd-3b33-4439-b504-d49aba53da26
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE
 pool-1-kworker1  aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker1  Online  500GiB    100GiB     400GiB
 ```

7. Pool Labelling
```
❯ kubectl openebs mayastor label pool pool-1-kworker1 zone-us=east-1
Pool pool pool-1-kworker1 labelled successfully. Current labels: {"zone-us": "east-1"}
 ```

8. Show pool labels.
```
❯ kubectl openebs mayastor get pools --show-labels
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE  LABELS
pool-1-kworker1   aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker3  Online  500GiB    100GiB     400GiB  zone-us=east-1

kubectl openebs mayastor get pool pool-1-kworker1 --show-labels
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE  LABELS
pool-1-kworker1   aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker3  Online  500GiB    100GiB     400GiB  zone-us=east-1
 ```

9. Select pools based on labels. Filer labels must be provided in `zone-us=east-1` format.
```
❯ kubectl openebs mayastor get pools --selector zone-us=east-1
 ID               DISKS                                                     MANAGED  NODE      STATUS  CAPACITY  ALLOCATED  AVAILABLE
pool-1-kworker1   aio:///dev/vdb?uuid=d8a36b4b-0435-4fee-bf76-f2aef980b833  true     kworker3  Online  500GiB    100GiB     400GiB
 ```

10. Pool Unlabelling
```
❯ kubectl openebs mayastor label pool pool-1-kworker1 zone-us-
Pool pool-1-kworker1 labelled successfully. Current labels: { }
 ```

11. Get Nodes
```
❯ kubectl openebs mayastor get nodes
 ID           GRPC ENDPOINT   STATUS                     VERSION
 io-engine-1  10.1.0.5:10124  Online, Cordoned           v2.7.0
 io-engine-3  10.1.0.7:10124  Online, Cordoned, Drained  v2.7.0
 io-engine-2  10.1.0.6:10124  Online                     v2.7.0
```
12. Get Node by ID
```
❯ kubectl openebs mayastor get node io-engine-1
 ID           GRPC ENDPOINT   STATUS            VERSION
 io-engine-1  10.1.0.5:10124  Online, Cordoned  v2.7.0
```
13. Replica topology for a specific volume
```
❯ kubectl openebs mayastor get volume-replica-topology ec4e66fd-3b33-4439-b504-d49aba53da26
 ID                                    NODE      POOL             STATUS  CAPACITY  ALLOCATED SNAPSHOTS  CHILD-STATUS  REASON  REBUILD
 b32769b8-e5b3-4e1c-9db0-89867470f6eb  kworker1  pool-1-kworker1  Online  384MiB    8MiB      12MiB      Degraded      <none>  75 %
 d3856829-22b3-414d-a01b-4b6467db14fb  kworker2  pool-1-kworker2  Online  384MiB    8MiB      64MiB      Online        <none>  <none>
```

13. Replica topology for all volumes
```
❯ kubectl openebs mayastor get volume-replica-topologies
VOLUME-ID                              ID                                    NODE      POOL             STATUS  CAPACITY  ALLOCATED SNAPSHOTS CHILD-STATUS  REASON      REBUILD
 c05ef923-a320-468c-b426-a260c1d84107  b58e1975-633f-4b34-9611-b648babf76a8  kworker1  pool-1-kworker1  Online  60MiB     36MiB     0MiB      Degraded      OutOfSpace  <none>
 ├─                                    67a6ec31-5923-490f-84b7-0be1df3bfb53  kworker2  pool-1-kworker2  Online  60MiB     60MiB     0MiB      Online        <none>      <none>
 └─                                    553aeb7c-4be4-4391-a403-ad241d96711f  kworker3  pool-1-kworker3  Online  60MiB     60MiB     0MiB      Online        <none>      <none>
 83241cc8-5dca-4bf1-b55a-c427c3e9b4a1  adde358f-70cd-4a2d-9dfb-f40d6663ecbc  kworker1  pool-1-kworker1  Online  20MiB     16MiB     0MiB      Degraded      <none>      51%
 ├─                                    b5ff41b8-1a0a-4bc7-84bb-5bfdfe72a71e  kworker2  pool-1-kworker2  Online  60MiB     60MiB     0MiB      Online        <none>      <none>
 └─                                    39431c11-0eea-48e7-970f-a2359ebbb9d1  kworker3  pool-1-kworker3  Online  60MiB     60MiB     0MiB      Online        <none>      <none>
```

14. Volume Snapshots by volumeID
```
❯ kubectl openebs mayastor get volume-snapshots --volume ec4e66fd-3b33-4439-b504-d49aba53da26
 ID                                    TIMESTAMP             SOURCE-SIZE  ALLOCATED-SIZE  TOTAL-ALLOCATED-SIZE  SOURCE-VOL                            RESTORES
 25823425-41fa-434a-9efd-a356b70b5d7c  2023-08-14T07:02:00Z  10MiB        12MiB           12MiB                 ec4e66fd-3b33-4439-b504-d49aba53da26  2

```

15. Get Volume Snapshots
```
❯ kubectl openebs mayastor get volume-snapshots
 ID                                    TIMESTAMP             SOURCE-SIZE  ALLOCATED-SIZE  TOTAL-ALLOCATED-SIZE  SOURCE-VOL                            RESTORES
 25823425-41fa-434a-9efd-a356b70b5d7c  2023-08-14T07:02:00Z  10MiB        12MiB           12MiB                 ec4e66fd-3b33-4439-b504-d49aba53da26  2
 5ee6e958-5917-41b5-abc8-c1f82ff102be  2023-08-14T07:12:39Z  10MiB        0 B             12MiB                 ec4e66fd-3b33-4439-b504-d49aba53da28  0

```

16. Volume Rebuild History by volumeID
```
❯ kubectl openebs mayastor get rebuild-history e898106d-e735-4edf-aba2-932d42c3c58d
DST                                   SRC                                   STATE      TOTAL  RECOVERED  TRANSFERRED  IS-PARTIAL  START-TIME            END-TIME
b5de71a6-055d-433a-a1c5-2b39ade05d86  0dafa450-7a19-4e21-a919-89c6f9bd2a97  Completed  7MiB   7MiB       0 B          true        2023-07-04T05:45:47Z  2023-07-04T05:45:47Z
b5de71a6-055d-433a-a1c5-2b39ade05d86  0dafa450-7a19-4e21-a919-89c6f9bd2a97  Completed  7MiB   7MiB       0 B          true        2023-07-04T05:45:46Z  2023-07-04T05:45:46Z

```

**NOTE: The above command lists volume snapshots for all volumes if `--volume` or `--snapshot` or a combination of both flags is not used.**

17. Get BlockDevices by NodeID
```
❯ kubectl openebs mayastor get block-devices kworker1 --all
 DEVNAME          DEVTYPE    SIZE       AVAILABLE  MODEL                       DEVPATH                                                         FSTYPE  FSUUID  MOUNTPOINT  PARTTYPE                              MAJOR            MINOR                                     DEVLINKS
 /dev/nvme1n1     disk       400GiB     no         Amazon Elastic Block Store  /devices/pci0000:00/0000:00:1f.0/nvme/nvme1/nvme1n1             259     4       ext4        4616cd08-7a7d-49fe-ae6d-908f9e864fc7                                                             "/dev/disk/by-uuid/4616cd08-7a7d-49fe-ae6d-908f9e864fc7", "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol04bfba0a58c4ffdae", "/dev/disk/by-id/nvme-nvme.1d0f-766f6c303462666261306135386334666664
 /dev/nvme4n1     disk       2TiB       yes        Amazon Elastic Block Store  /devices/pci0000:00/0000:00:1d.0/nvme/nvme4/nvme4n1             259     12                                                                                                                   "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol06eb486c9593587a9", "/dev/disk/by-id/nvme-nvme.1d0f-766f6c3036656234383663393539333538376139-416d617a6f6e20456c617374696320426c6f636b2053746f7265-00000001", "/dev/disk/by-path/pci-0000:00:1d.0-nvme-1"
 /dev/nvme2n1     disk       1TiB       no         Amazon Elastic Block Store  /devices/pci0000:00/0000:00:1e.0/nvme/nvme2/nvme2n1             259     5                                                                                                                    "/dev/disk/by-id/nvme-nvme.1d0f-766f6c3033623636623930363535636636656465-416d617a6f6e20456c617374696320426c6f636b2053746f7265-00000001", "/dev/disk/by-path/pci-0000:00:1e.0-nvme-1", "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol03b66b90655cf6ede"
```
```
❯ kubectl openebs mayastor get block-devices kworker1
 DEVNAME       DEVTYPE  SIZE      AVAILABLE  MODEL                       DEVPATH                                              MAJOR  MINOR  DEVLINKS
 /dev/nvme4n1  disk     2TiB      yes        Amazon Elastic Block Store  /devices/pci0000:00/0000:00:1d.0/nvme/nvme4/nvme4n1  259    12     "/dev/disk/by-id/nvme-Amazon_Elastic_Block_Store_vol06eb486c9593587a9", "/dev/disk/by-id/nvme-nvme.1d0f-766f6c3036656234383663393539333538376139-416d617a6f6e20456c617374696320426c6f636b2053746f7265-00000001", "/dev/disk/by-path/pci-0000:00:1d.0-nvme-1"
```
**NOTE: The above command lists usable blockdevices if `--all` flag is not used, but currently since there isn't a way to identify whether the `disk` has a blobstore pool, `disks` not used by `pools` created by `control-plane` are shown as usable if they lack any filesystem uuid.**

18. Snapshot topology for a specific volume
```
❯ kubectl openebs mayastor get volume-snapshot-topology --volume ec4e66fd-3b33-4439-b504-d49aba53da26
 SNAPSHOT-ID                           ID                                    POOL    SNAPSHOT_STATUS  SIZE      ALLOCATED_SIZE  SOURCE
 25823425-41fa-434a-9efd-a356b70b5d7c  b2241dfb-f0a8-4fcc-a7d4-31bbccc66757  pool-3  Offline                                    2ffac7e4-d017-4844-9ae3-10d94bbfea73
 ├─                                    b197eac8-2dc0-41d6-9097-3d21d3b734e8  pool-1  Online           12582912  12582912        8f764ec7-a119-4403-9389-121e087262a4
 └─                                    a3c3b1ab-a1da-4db0-816f-56c0d09ece57  pool-2  Online           12582912  12582912        6b7963de-c994-4134-b5d7-540a4a554d44
 25823425-41fa-434a-9efd-a356b70b5d7d  95767535-a537-4a86-83bd-a304d183434d  pool-3  Offline                                    2ffac7e4-d017-4844-9ae3-10d94bbfea73
 ├─                                    9e39117e-96fa-46a0-a7ee-6d004e3b3495  pool-1  Online           12582912  0               8f764ec7-a119-4403-9389-121e087262a4
 └─                                    79f15ccb-0ac6-4812-936e-57055430a2d6  pool-2  Online           12582912  0               6b7963de-c994-4134-b5d7-540a4a554d44
 ```
 ```
❯ kubectl openebs mayastor get volume-snapshot-topology --snapshot 25823425-41fa-434a-9efd-a356b70b5d7c
 SNAPSHOT-ID                           ID                                    POOL    SNAPSHOT_STATUS  SIZE      ALLOCATED_SIZE  SOURCE
 25823425-41fa-434a-9efd-a356b70b5d7c  b2241dfb-f0a8-4fcc-a7d4-31bbccc66757  pool-3  Offline                                    2ffac7e4-d017-4844-9ae3-10d94bbfea73
 ├─                                    b197eac8-2dc0-41d6-9097-3d21d3b734e8  pool-1  Online           12582912  12582912        8f764ec7-a119-4403-9389-121e087262a4
 └─                                    a3c3b1ab-a1da-4db0-816f-56c0d09ece57  pool-2  Online           12582912  12582912        6b7963de-c994-4134-b5d7-540a4a554d44

 ```

</details>

<details>
<summary> Node Cordon, Drain and Label Operations </summary>

1. Node Cordoning
```
❯ kubectl openebs mayastor cordon node kworker1 my_cordon_1
Node node-1-14048 cordoned successfully
```
2. Node Uncordoning
```
❯ kubectl openebs mayastor uncordon node kworker1 my_cordon_1
Node node-1-14048 successfully uncordoned
```
3. Get Cordon
```
❯ kubectl openebs mayastor get cordon node node-1-14048
 ID            GRPC ENDPOINT        STATUS  CORDONED  CORDON LABELS
 node-1-14048  95.217.158.66:10124  Online  true      my_cordon_1

❯ kubectl openebs mayastor get cordon nodes
 ID            GRPC ENDPOINT        STATUS  CORDONED  CORDON LABELS
 node-2-14048  95.217.152.7:10124   Online  true      my_cordon_2
 node-1-14048  95.217.158.66:10124  Online  true      my_cordon_1
```
4. Node Draining
```
❯ kubectl openebs mayastor drain node io-engine-1 my-drain-label
Node node-1-14048 successfully drained

❯ kubectl openebs mayastor drain node node-1-14048 my-drain-label --drain-timeout 10s
Node node-1-14048 drain command timed out
```
5. Cancel Node Drain (via uncordon)
```
❯ kubectl openebs mayastor uncordon node io-engine-1 my-drain-label
Node io-engine-1 successfully uncordoned
```
6. Get Drain
```
❯ kubectl openebs mayastor get drain node node-2-14048
 ID            GRPC ENDPOINT       STATUS  CORDONED  DRAIN STATE  DRAIN LABELS
 node-2-14048  95.217.152.7:10124  Online  true      Draining     my_drain_2

❯ kubectl openebs mayastor get drain node node-0-14048
 ID            GRPC ENDPOINT          STATUS  CORDONED  DRAIN STATE   DRAIN LABELS
 node-0-14048  135.181.206.173:10124  Online  false     Not draining

❯ kubectl openebs mayastor get drain nodes
 ID            GRPC ENDPOINT        STATUS  CORDONED  DRAIN STATE  DRAIN LABELS
 node-2-14048  95.217.152.7:10124   Online  true      Draining     my_drain_2
 node-1-14048  95.217.158.66:10124  Online  true      Drained      my_drain_1

```
7. Node Labeling
```
❯ kubectl openebs mayastor label node kworker1 zone-us=east-1
Node node-1-14048  labelled successfully. Current labels: {"zone-us": "east-1"}
```
8. Node Unlabelling
```
❯ kubectl openebs mayastor label node kworker1 zone-us-
Node node-1-14048 labelled successfully. Current labels: {}
```
</details>

<details>
<summary> Scale Resources operations </summary>

1. Scale Volume by ID
```
❯ kubectl openebs mayastor scale volume 0c08667c-8b59-4d11-9192-b54e27e0ce0f 5
Volume 0c08667c-8b59-4d11-9192-b54e27e0ce0f Scaled Successfully 🚀

```
</details>

<details>
<summary> Set Resources operations </summary>

1. Set Volume Resource by ID
```
❯ kubectl openebs mayastor set volume ec4e66fd-3b33-4439-b504-d49aba53da26 max-snapshots 30
Volume ec4e66fd-3b33-4439-b504-d49aba53da26 property max_snapshots(30) set successfully

```
</details>

<details>
<summary> Support operations </summary>

```sh
kubectl openebs mayastor dump
Usage: kubectl-openebs mayastor dump [OPTIONS] <COMMAND>

Commands:
  system  Collects entire system information
  etcd    Collects information from etcd
  help    Print this message or the help of the given subcommand(s)

Options:
  -r, --rest <REST>
          The rest endpoint to connect to
  -t, --timeout <TIMEOUT>
          Specifies the timeout value to interact with other modules of system [default: 10s]
  -k, --kube-config-path <KUBE_CONFIG_PATH>
          Path to kubeconfig file
  -s, --since <SINCE>
          Period states to collect all logs from last specified duration [default: 24h]
  -l, --loki-endpoint <LOKI_ENDPOINT>
          Endpoint of LOKI service, if left empty then it will try to parse endpoint from Loki service(K8s service resource), if the tool is unable to parse from service then logs will be collected using Kube-apiserver
  -e, --etcd-endpoint <ETCD_ENDPOINT>
          Endpoint of ETCD service, if left empty then will be parsed from the internal service name
  -d, --output-directory-path <OUTPUT_DIRECTORY_PATH>
          Output directory path to store archive file [default: ./]
  -n, --namespace <NAMESPACE>
          Kubernetes namespace of mayastor service [default: mayastor]
  -o, --output <OUTPUT>
          The Output, viz yaml, json [default: none]
  -j, --jaeger <JAEGER>
          Trace rest requests to the Jaeger endpoint agent
  -h, --help
          Print help

Supportability - collects state & log information of services and dumps it to a tar file.
```

**Note**: Each subcommand supports `--help` option to know various other options.


**Examples**:

To collect entire mayastor system information into an archive file
```sh
## Command
kubectl openebs mayastor dump system -d <output_directory> -n <mayastor_namespace>
```
 <b>`--disable-log-collection` can be used to disable collection of logs.</b>

</details>
<details>
<summary> Upgrade operations </summary>

**Examples**:

1. Upgrade deployment
```
  ## Command
  kubectl openebs mayastor upgrade
  `Upgrade` the deployment

  Usage: kubectl-openebs mayastor upgrade [OPTIONS]

  Options:
  -d, --dry-run
          Display all the validations output but will not execute upgrade
  -r, --rest <REST>
          The rest endpoint to connect to
  -k, --kube-config-path <KUBE_CONFIG_PATH>
          Path to kubeconfig file
      --skip-data-plane-restart
          If set then upgrade will skip the io-engine pods restart
      --skip-single-replica-volume-validation
          If set then it will continue with upgrade without validating singla replica volume
      --skip-replica-rebuild
          If set then upgrade will skip the repilca rebuild in progress validation
      --skip-cordoned-node-validation
          If set then upgrade will skip the cordoned node validation
      --set <SET>
          The set values on the command line. (can specify multiple or separate values with commas: key1=val1,key2=val2)
      --set-file <SET_FILE>
          The set values from respective files specified via the command line (can specify multiple or separate values with commas: key1=path1,key2=path2)
  -o, --output <OUTPUT>
          The Output, viz yaml, json [default: none]
  -j, --jaeger <JAEGER>
          Trace rest requests to the Jaeger endpoint agent
  -n, --namespace <NAMESPACE>
          Kubernetes namespace of mayastor service [default: mayastor]
  -h, --help
          Print help
```

2. Get the upgrade status
```
   ## Command
   kubectl openebs mayastor get upgrade-status
   `Get` the upgrade status

   Usage: kubectl-openebs mayastor get upgrade-status [OPTIONS]

   Options:
   -r, --rest <REST>
        The rest endpoint to connect to
   -k, --kube-config-path <KUBE_CONFIG_PATH>
        Path to kubeconfig file
   -o, --output <OUTPUT>
        The Output, viz yaml, json [default: none]
   -j, --jaeger <JAEGER>
        Trace rest requests to the Jaeger endpoint agent
   -n, --namespace <NAMESPACE>
        Kubernetes namespace of mayastor service [default: mayastor]
   -h, --help
        Print help
   ```

3. Delete upgrade resources
```
   ## Command
   kubectl openebs mayastor delete upgrade
  `Delete` the upgrade resources

  Usage: kubectl-openebs mayastor delete upgrade [OPTIONS]

  Options:
  -f, --force
        If true, immediately remove upgrade resources bypass graceful deletion
  -r, --rest <REST>
        The rest endpoint to connect to
  -k, --kube-config-path <KUBE_CONFIG_PATH>
        Path to kubeconfig file
  -o, --output <OUTPUT>
        The Output, viz yaml, json [default: none]
  -j, --jaeger <JAEGER>
        Trace rest requests to the Jaeger endpoint agent
  -n, --namespace <NAMESPACE>
        Kubernetes namespace of mayastor service [default: mayastor]
  -h, --help
          Print help

```
</details>

### LocalPV-LVM

<details>
<summary> General Resources operations </summary>

1. Get Volumes
```
❯  kubectl openebs localpv-lvm get volumes
 NAME                                      NODE           STATUS  CAPACITY  VOLGROUP  PVC-NAME           SC-NAME
 pvc-27940181-6ad5-49e9-8661-197359f36403  node-2-309787  Ready   2.00 GiB  data      pvc-thin-topo      openebs-lvmpv
 pvc-5d13e956-5ee0-44aa-ad01-d66272c2dfc4  node-2-309787  Ready   2.00 GiB  data      pvc-thin-topo-new  openebs-lvmpv
```
2. Get Volume by ID
```
❯  kubectl openebs localpv-lvm get volume pvc-27940181-6ad5-49e9-8661-197359f36403
 NAME                                      NODE           STATUS  CAPACITY  VOLGROUP  PVC-NAME       SC-NAME
 pvc-27940181-6ad5-49e9-8661-197359f36403  node-2-309787  Ready   2.00 GiB  data      pvc-thin-topo  openebs-lvmpv

```
3. Get Volume Groups (All vg in the clsuter are listed)
```
❯  kubectl openebs localpv-lvm get volume-groups
 NAME  NODE           UUID                                    TOTAL-SIZE  FREE-SIZE  LV-COUNT  PV-COUNT  SNAP-COUNT
 data  node-2-309787  NbWcos-TcId-B0QN-bqPs-PgGi-XNeu-VactuK  30716Mi     26620Mi    2         1         0
 data  node-3-309787  hofr37-rsfh-H3uf-ml4r-d0Yw-4V2h-fyzT3F  30716Mi     30716Mi    0         1         0
```
4. Get Volume Groups by Node-id

```
❯  kubectl-openebs localpv-lvm get volume-groups node-2-309787  -n puls8
 NAME  NODE           UUID                                    TOTAL-SIZE  FREE-SIZE  LV-COUNT  PV-COUNT  SNAP-COUNT
 data  node-2-309787  NbWcos-TcId-B0QN-bqPs-PgGi-XNeu-VactuK  30716Mi     26620Mi    2         1         0
 ```


</details>

### LocalPV-ZFS

<details>
<summary> General Resources operations </summary>

1. Get Volumes
```
❯  kubectl openebs localpv-zfs get volumes
 NAME                                      NODE           STATUS  CAPACITY  POOL        PVC-NAME       SC-NAME
 pvc-1771831c-b1f9-45d9-91b2-e8de98372586  node-0-309787  Ready   4.00 GiB  zfspv-pool  csi-zfspv      openebs-zfspv
 pvc-1be09a53-f334-4a2b-a8cd-ee99a17ecff5  node-1-309787  Ready   4.00 GiB  zfspv-pool  csi-zfspv-new  openebs-zfspv
```
2. Get Volume by ID
```
❯  kubectl openebs localpv-zfs get volume pvc-1771831c-b1f9-45d9-91b2-e8de98372586
NAME                                      NODE           STATUS  CAPACITY  POOL        PVC-NAME       SC-NAME
pvc-1771831c-b1f9-45d9-91b2-e8de98372586  node-0-309787  Ready   4.00 GiB  zfspv-pool  csi-zfspv      openebs-zfspv

```
3. Get Zpools (All zpool in the clsuter are listed)
```
❯  kubectl openebs localpv-zfs get zpools
 NAME        NODE           UUID                  FREE         USED
 zfspv-pool  node-0-309787  965947675669908193    29966204Ki   99Ki
 zfspv-pool  node-1-309787  10029612145612829144  29966206Ki   99Ki
```
4. Get Zpools by Node Id

```
❯  kubectl openebs localpv-zfs get zpools node-0-309787
  NAME        NODE           UUID                  FREE         USED
  zfspv-pool  node-0-309787  965947675669908193    29966204Ki   99Ki
 ```

</details>

### LocalPV-Hostpath

<details>
<summary> General Resources operations </summary>


1. Get Volumes
```
❯  kubectl openebs localpv-hostpath get volumes
NAME                                      NODE                         STATUS  CAPACITY  PATH                                                                               PVC-NAME                SC-NAME
 pvc-8fdd870a-b71b-45af-9106-33ad114121ad  node-0-309787  Bound   10Gi      /var/local/openebs/localpv-hostpath/loki/pvc-8fdd870a-b71b-45af-9106-33ad114121ad  storage-openebs-loki-0  mayastor-loki-localpv

