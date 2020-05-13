---
title: Easy to use cli for OpenEBS
authors:
  - "@vaniisgh"
creation-date: 2020-05-13
last-updated: 2020-05-13
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
infrastructure of the deployment and use long shell commands to configure the 
package. This intern takes away from the ease of use of the package and may 
discourage a certain group of users from exploring the features of available.
To tackle this problem and allow the user deploy/edit/update/checkup on their 
deployment a plugin for kubectl would have utility. 
One such implementation exists as the *mayactl* tool that provides the 
users of the maya-apiserver a simple and elegant solution to interact with their 
pods and services.
A robust testing for each cli command will ensure that the user is able to configure
resources as expected.
 
## Proposal

An easy to use, lightweight cli tool package written in GO & shell which should 
have intuitive commands providing the user a reliable and fast solution for 
their interaction with their OpenEBS database.

This tool should contain commands and flags that would help users and developers
not just during setup but also during development (like logging, performance 
testing), this give them the flexibility to access their storage independently
and easily.

Plugins of major stateful application that are often deployed using openEBS 
should also be supported ex. kubeMove,valero etc.

The tool itself should be installed using a curl command or installed as a 
helm chart or built from source from within the openEBS github repository.

### Proposed Usage Options

a command should look like :

```bash
openebs install/inject test.yml --verbose  - | kubectl apply -f -    
```

Some other commands could be :
  -install                  => Install OpenEBS
  -upgrade                  => Upgrade OpenEBS components
  -version                  => Print the OpenEBS version and associated images
  
  -verify iSCSI service     => A required prerequisite of OpenEBS
  -verify permissions       => Verify weather OpenEBS can be configured onto the cluster
  -discover                 => list the possible deployment options to the user leveraging ndm
  -status                   => Print the readiness of various components, verify prerequisites are met to run Openebs pools and volumes.
  -<resource-name> describe => gives info about the resource configuration
  
  -create                   => Create OpenEBS resources ( like cStor Pools, Storage Classes)
  -launch                   => Launch OpenEBS resources
  -edit_config              => Edit configuration (i.e configure limits of related pods)
  -list_config              => lists the configuration of the stack
  
  -delete                   => Delete OpenEBS resources 

-for each of these commands we could have simple flags like: --help, --version, 
--verbose, --log level, --trace

- it should allow a yaml file to be injected which specifies the users deployment.




#### Proposed Implementation

Keeping the file structure simple like :

CLI
|__cmd
|   |__install.go
|   :
|   :
|   |__edit_config.go
|
|__main.go


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

  },

  // return other options	
}
```





