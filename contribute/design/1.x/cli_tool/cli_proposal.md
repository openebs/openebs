---
title: Easy to use cli for OpenEBS + ( mini test suite + doccumentation)
authors:
  - "@vaniisgh"
creation-date: 2020-05-13
last-updated: 2020-05-14
status: proposed
---

## Easy to use command-line interface (CLI) for OpenEBS

## Table of Contents

  * [Table of Contents](#table-of-contents)
  * [Summary](#summary)
  * [Proposal](#proposal)
  * [Proposed Usage Options](#proposed-usage-options)
  * [Proposed Implementation](#proposed-implementation)

### Summary

OpenEBS is completely Kubernetes native and is implemented using microservices.
Currently OpenEBS can be installed via kubectl or helm chart. And managed via
a few custom resources.
Often these require the user to have detailed knowledge of the underlying
infrastructure of the deployment and use long kubectl commands as well as knowledge
of Kubernetes versions and architrcure to configure the sotrage. This intern takes
away from the ease of use of the package and may discourage a certain group of users
from exploring the features of available.
To tackle this problem and allow the user deploy/edit/update/checkup on their
deployment a plugin for kubectl would have utility.
One such implementation exists as the *mayactl* tool that provides the
users of the maya-apiserver a simple and elegant solution to interact with their
pods and services.
A robust testing for each cli command will ensure that the user is able to configure
resources as expected.

## Proposal

An easy to use, lightweight cli tool package written in GO.

It could extend the maya CLI tool to:

1. Help user configure the sotorage without much knowledge using a single yaml file

2. Provide a hierarchical picture of the containerized storage instances from
controller to replica and provide an output that gives details of the PODs its serving
and storage too. It should also show what replicas are involved and their status and
how they are connected to the controller which glues them all together.

### Goals

1. Provide commands and flags to help users and developers not just during setup but also during development (like logging, performance testing).
2. Allow single command installation. ex. in case of Dynamic Volume Provisioning on ZFS install a simple :

    ```bash
      kubectl openebs install zfs-localpv -namespace namespace
    ```

    1. Command should install install zfsutils-linux
    2. Create and Attach the disk or notify if already attached zpool on each node using the attached disks
    3. Create zpools on each existing node
    4. List the zpools
    5. Install OpenEBS ZFS driver
    6. Notify that installation is successfull

3. To give users the flexibility to access their storage independently and easily.
4. Support plugins that are deployed using on openEBS ex. kubeMove,valero etc.
5. To facilitate deployment for of major stateful applications that use OpenEBS
seamlessly.
6. Add a test that runs a job that identifies the nodes that will run the stateful
workloads.
7. Add a suite of tests that are easy to apply on the repository with a simple commad
like ``` go test -cover -race ./... ```

### Proposed Usage Options

The tool itself should be installed using a curl command or installed as a
helm chart or built from source from within the openEBS github repository.

commands should look like :

    ```bash
      kubectl openebs status --verbose  
      kubectl openebs install
    ```

Some other commands could be :

  - install                  => Install OpenEBS
  - upgrade                  => Upgrade OpenEBS components
  - version                  => Print the OpenEBS version and associated images
  
  - verify iSCSI service     => A required prerequisite of OpenEBS
  - verify permissions       => Verify weather OpenEBS can be configured onto the cluster
  - discover                 => list the possible deployment options to the user leveraging ndm
  - status                   => Print the readiness of various components, verify prerequisites are met to run Openebs pools and volumes.
  - resource-name describe => gives info about the resource configuration
  
  - create                   => Create OpenEBS resources ( like cStor Pools, Storage Classes)
  - launch                   => Launch OpenEBS resources
  - edit_config              => Edit configuration (i.e configure limits of related pods)
  - extend                   => Extend the 
  - list_config              => lists the configuration of the stack
  
  - delete                   => Delete OpenEBS resources in the namespace

for each of these commands we should include the basic flags like: --help, --version, --verbose, --log level, --trace

#### Proposed Implementation

Keeping the file structure simple like :

```
CLI
|__cmd
|   |__*testdata
|   |__install.go
|   |__install_test.go
|   :
|   :
|   |__edit_config.go
|   |__edit_config_test.go
|
|__main.go
```

the main.go file should be simple and clean like so :

    ```go
    package main  
    import (
    "os"
    "github.com/OpenEBS/cli/cmd"
    )

    func main() {
      if err := cmd.RootCmd.Execute(); err != nil {
        os.Exit(1)
      }
    }
    ```

while each command should have its separate module in the cmd package

    ```go
    package cmd

    import (
      OEBScharts"github.com/openebs/openebs/tree/master/k8s/charts/openebs"
      "github.com/openebs/openebs/tree/master/k8s"
	    "github.com/spf13/cobra"
    )

    // constants should be defined for command line constants
    // constants should be defined for where possible plugins are stored

    //to install OpenEBS 
    func newCmdInstall(*installOptions, err) *cobra.Command {
      defaults, err := OEBScharts.NewValues(false)

      //return an error if installation fails
      if err != nil {
        return nil, err
      }


    return &installOptions{
      PoolDomain:                  defaults.Global.PoolDomain,
      controlPlaneVersion:         version.Version,
      cStorPoolReplicas:           defaults.cStorPoolReplicas,
      : 
      :
      },

      // return other options
    }
    ```

#### Related Issues

- [2946](https://github.com/openebs/openebs/issues/2946)
- [1248](https://github.com/openebs/openebs/issues/1248)
- [1216](https://github.com/openebs/openebs/issues/1216)
- [290](https://github.com/openebs/openebs/issues/290)
