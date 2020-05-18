---
title: Easy to use CLI for OpenEBS
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
* [Related Issues](#related-issues)

### Summary

OpenEBS is widely used as a storage solution for aplications that run on
Kubernetes. It is completely Kubernetes native and is implemented using microservices.
Currently OpenEBS can be installed via kubectl or hel using a chart. And managed via
custom resources. These require the user to have knowledge of the OpenEBS architecture.
They need to use long kubectl commands to gateher details and interact with OpenEBS
componenets. This takes away from the ease of use of the package and may discourage
a certain of users from exploring the features of available. To tackle this problem
and allow the user deploy/edit/update/checkup on their deployment a plugin for
kubectl could be developed.
One such implementation exists as the *mayactl* tool that provides the
users of the maya-apiserver a simple and elegant solution to interact with their
pods and services.
A robust testing for each cli command will ensure that the user is able to configure
resources as expected. Doccumentation of each command will provide a detailed overview
of the utility and options to first time viewers and users.

## Proposal

An easy to use, lightweight cli tool package written in GO.

The tool (like the existing mayactl tool) will be used to:

1. Help user configure the OpenEBS without much knowledge using a single yaml file, and
simle CLI commands.
2. Provide a hierarchical picture of the containerized storage instances from
controllers to replicas, provide an output that gives details of the pods it's serving
and their storage configuration too and status of the replicas involved.
3. The tool is meant to act as a one stop solution for all the users basic OpenEBS needs.

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
6. Add tests that runs a jobs that identify the nodes that will be able run the stateful
workloads.
7. Add a suite of tests that are easy to apply on the repository with a simple commad
like ``` go test -cover -race ./... ``` leveraging the functions defined in the cli-tool.

This proposal doesn't aim to add new features to OpenEBS, it only aims to add a new way
for any user to interact with OpenEBS.

### Proposed Usage Options

The tool itself should be installed using a curl command or installed as a
helm chart or built from source from within the openEBS github repository.

commands should look like :

  ```bash
      kubectl openebs status --verbose  
      kubectl openebs apply <apply-options>.yml
  ```

Some other commands could be :

* apply                    => use OpenEBS
* upgrade                  => Upgrade OpenEBS components
* version                  => Print the OpenEBS version and associated images
  
* verify iSCSI service     => A required prerequisite of OpenEBS
* verify permissions       => Verify weather OpenEBS can be configured onto the cluster
* discover                 => list the possible deployment options to the user leveraging ndm
* status                   => Print the readiness of various components, verify prerequisites are met to run Openebs pools and volumes.
* resource-name describe   => gives info about the resource configuration
  
* create                   => Create OpenEBS resources ( like cStor Pools, Storage Classes)
* launch                   => Launch OpenEBS resources
* edit_config              => Edit configuration (i.e configure limits of related pods)
* extend                   => Extend the 
* list_config              => lists the configuration of the stack
  
* delete                   => Delete OpenEBS resources in the namespace

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
    func newCmdDiscover(*clusterOptions, err) *cobra.Command {
      defaults, err := OEBScharts.NewValues(false)

      //return an error if cluster options dont meet expectations
      if err != nil {
        return nil, err
      }


    return &discoverOptions{
      poolDomain:                  defaults.Global.PoolDomain,
      controlPlaneVersion:         version.Version,
      storageOptions:              defaults.StorageOptions,
      :
      :
      },

      // return other options
    }
  ```

#### Related Issues

* [2946](https://github.com/openebs/openebs/issues/2946)
* [1248](https://github.com/openebs/openebs/issues/1248)
* [1216](https://github.com/openebs/openebs/issues/1216)
* [290](https://github.com/openebs/openebs/issues/290)
