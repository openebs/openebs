.. Release Notes

*******************
Changelog
*******************

You can try out OpenEBS v0.4.0 on your Kubernetes Cluster using the `quick start guide`_. 
 
.. _quick start guide: http://openebs.readthedocs.io/en/latest/getting_started/quick_install.html

Downloads for v0.4.0
=====================
The following OpenEBS v0.4.0 containers are available at the `Docker Hub`_.

.. _Docker Hub: https://hub.docker.com/r/openebs/
* openebs/jiva:0.4.0 : Storage Controller
* openebs/m-apiserver:0.4.0 : OpenEBS Maya API Server along with the latest maya cli.
* openebs/openebs-k8s-provisioner:0.4.0 : Dynamic OpenEBS Volume Provisioner for Kubernetes.

New v0.4.0 Features
=====================
* Maya CLI Support for managing snapshots for OpenEBS Volumes
* Maya CLI Support for obtaining the capacity usage statistics from OpenEBS Volumes
* OpenEBS Volume - Dynamic Provisioner is merged into kubernetes-incubator/external-storage project
* OpenEBS Maya API Server uses the Kubernetes scheduler logic to place OpenEBS Volume Replicas on different nodes
* OpenEBS Maya API Server can be customized by providing ENV options through K8s YAML file for default replica count and jiva image to be used
* OpenEBS user documentation is available at http://openebs.readthedocs.io/en/latest/
* OpenEBS now supports deployment on AWS, along with previously supported Google Cloud and On-premise setups
* OpenEBS Vagrant boxes are upgraded to support Kubernetes version 1.7.5
* OpenEBS can now be deployed within a minikube setup

Issues Fixed in v0.4.0
==============================
* #166 (https://github.com/edorid): openebs-k8s-provisioner goes into crashloopbackoff, during the first volume creation
* #176 (https://github.com/maikotz): OpenEBS PV is unreachable after one of the replica becomes unreachable.

Known Issues in v0.4.0
==============================
* #633 (https://github.com/openebs/openebs/issues/633): 

**Issue:**

Setting up OpenEBS with Kubernetes using Minikube on the Ubuntu host displayed the following error.
*error: error validating "openebs-operator.yaml": error validating data: unknown object type schema.GroupVersionKind{Group:"", Version:"v1", Kind:"ServiceAccount"}; if you choose to ignore these errors, turn validation off with --validate=false*

**Resolution**

1. Download a specific/compatible version, by replacing the **$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt))** portion of the command with a specific version.

   For example, to download v1.8.0 on Linux, enter the following command.
   ::
      curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl

2. Make the kubectl binary executable.
   ::
      chmod +x ./kubectl
3. Move the binary in to your PATH.
   :: 
      sudo mv ./kubectl /usr/local/bin/kubectl

CI Updates with v0.4.0
=========================
* Support for on-premise Jenkins CI for performing e2e tests
* iSCSI compliance tests are run as part of the CI
* CI can now be extended using a framework developer for running storage benchmark tests with vdbench or fio.
* CI has been extended to run Percona Benchmarking tests on Kubernetes.

Deprecated with v0.4.0
=========================
The maya cli options (setup-omm, setup-osh, omm-status, osh-status) to setup and manage dedicated OpenEBS setup is removed. Starting with v0.4.0, only hyperconvergence with Kubernetes is supported.

Notes for Contributors
=========================
* OpenEBS user documentation is currently being moved into *openebs/openebs/documentation*
* OpenEBS developer documentation is currently being added to *openebs/openebs/contribute*
* The deployment and e2e functionality will continue to be located in *openebs/k8s* and *openebs/e2e* respectively.
* openebs/maya will act as a single repository for hosting different OpenEBS Storage Control plane (orchestration) components.
* New /metrics handlers are being added to OpenEBS components to allow integration into tools like Prometheus.
* *openebs/maya/cmd/maya-agent* which will be deployed as a deamon-set running along-side kubelet is being developed. maya-agent will augument the kubelet with storage management functionality.
