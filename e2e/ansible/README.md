# Ansible Based CI Framework For OpenEBS
----------------------------------------

## Purpose

This project aims to provide an automated deployment & test framework for OpenEBS using the popular workflow
orchestration tool Ansible,while using python & shell scripts for auxiliary purposes. While the primary 
purpose of this project is to ensure quick validation of commits made into OpenEBS repos and keep it free of issues,
it can also be used to automate the on-premise deployment of OpenEBS. 

In its current form, this project performs an automated setup of:

- Kubernetes cluster (K8s-master, K8s-minions)
- OpenEBS cluster (openEBS-maya server,openEBS-storage hosts)

The OpenEBS installation can be performed either in __dedicated mode__, with the openebs storage services
running directly on linux machines (same as the ones hosting kubernetes cluster OR distinct boxes) OR
in __hyperconverged mode__, where the maya-server and openebs storage hosts are run as pods on the kubernetes
cluster

The detailed steps to perform this on-premise installation can be found here : 

https://github.com/ksatchit/openebs/blob/master/e2e/ansible/openebs-on-premise-deployment-guide.md

You can also validate the setup be running some simple applications on OpenEBS storage, either as Kubernetes pods 
(mysql, percona-mysql) or as containers running directly on the test-harness machine (fio, iometer).

Going ahead, this project is expected to evolve to provide additional configuration options for OpenEBS deployment 
and include a greater number of test scenarios.

## Ansible

At the outset, ansible was primarily preferred in view of its agent-less architecture, batch 
deployment capabilities, idempotent nature of task execution & YAML usage

To know more about Ansible, visit : http://docs.ansible.com/ansible/index.html

## Directory Layout Of The CI-CD Project

A broad listing of the folders in this project is provided below. 

```
ansible
├── files
├── inventory
│   └── group_vars
|   └── host_vars
├── playbooks
│   └── dedicated
│   └── hyperconverged
├── plugins
│   └── callback
└── roles
    ├── cleanup
    ├── common
    ├── fio
    ├── hosts
    ├── inventory
    ├── iometer
    ├── k8s-hosts
    ├── k8s-localhost
    ├── k8s-master
    ├── kubernetes
    ├── localhost
    ├── master
    ├── prerequisites
    ├── vagrant
    └── volume
  
```
## Limitations

Currently, the ansible playbooks are written to work with Ubuntu hosts. Going ahead, they will be enhanced to work on 
other linux flavours 

### Contributions

If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are warmly welcome.













