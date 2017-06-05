# ANSIBLE BASED CI FRAMEWORK FOR OPENEBS
----------------------------------------

## PURPOSE

This project aims to provide an automated deployment & test framework for OpenEBS using the popular provisioning & 
configuration management tool Ansible,while using python & shell scripts for auxiliary purposes. While the primary 
purpose of this project is to ensure quick validation of commits made into openebs repos and keep it free of issues,
it can also be used to automate the on-premise deployment of openebs. 

In its current form, this project performs an automated setup of:

- Kubernetes cluster (k8s-master, k8s-minions) configured with openebs flexvol driver for K8s
- Openebs cluster (openebs-maya server,openebs-storage hosts)

The detailed steps to perform this on-premise installation can be found here : 

https://github.com/ksatchit/openebs/blob/master/e2e/ansible/openebs-on-premise-deployment-guide.md

You can also validate the setup be running some simple applications on OpenEBS storage, either as kubernetes pods 
(mysql, percona-mysql) or as containers running directly on the test-harness machine (fio, iometer).

Going ahead, this project is expected to evolve to provide additional configuration options for openebs deployment 
and include a greater number of test scenarios.

## ANSIBLE

At the outset, ansible was preferred as the primary automation tool in view of its agent-less architecture, batch 
deployment capabilities, idempotent nature of task execution & YAML usage

More details about Ansible and its advantages can be found in here : http://docs.ansible.com/ansible/index.html

## DIRECTORY LAYOUT OF THE CI-CD PROJECT

A broad listing of the folders in this project is provided below. 

```
ansible
├── files
├── inventory
│   └── group_vars
├── playbooks
│   ├── test-k8s-mysql-pod
│   └── test-k8s-percona-mysql-pod ..etc..,
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
## LIMITATIONS

Currently, the ansible playbooks are written to work with Ubuntu hosts. Going ahead, they will be enhanced to work on 
other linux flavours 

### CONTRIBUTIONS

If you'd like to contribute, please fork the repository and use a feature branch. Pull requests are warmly welcome.













