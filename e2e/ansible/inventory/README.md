# Ansible Inventory
-------------------

This is the ansible default directory that holds the ```hosts``` file, which contains details of the host machines on which
ansible tasks are executed.

A brief description of the files in this directory is given below :

- machines.in : Input file consisting of comma separated lines used by the pre-requisites playbook to generate ansible ```hosts```
  file
- hosts : Default inventory file referred to in the playbooks
- group_vars/all.yml : Contains global variables for ansible playbooks
- host_vars/localhost.yml : Contains localhost attributes such as sudo password which are needed for privilege escalation

The machines.in needs to be updated with the details of the hosts used in the openebs setup prior to execution of the ansible
playbooks. Provided below are some instructions to consider while doing this

- Specify the machine details in the following manner :

    hostcode,ipaddress,env(username),env(password) where,

- hostcode is an identifier for the host machine and will be the name by which ansible will identify the machine. Ensure supported
  host codes are provided, failing which inventory generation will not proceed. Current supported codes include 'localhost, 'mayamaster',
  'mayahost', 'kubemaster', 'kubeminion'

- A dictionary of supported codes ("SupportedHostCodes") is present in the python script files/generate_inventory.py, which can be
  updated by interested users to include additional hostcodes

- The 'localhost' hostcode is a mandatory line in this file and has a default IP of 127.0.0.1

- Ensure the environment variables are set in the .profile of the ansible user

- Lines can be commented (such as these) by inserting '#' symbol before the host code

The contents of a typical ansible inventory 'hosts' file is as shown below :

```
localhost ansible_connection=local ansible_become_pass="{{ lookup('env','LOCAL_USER_PASSWORD') }}"

[openebs-mayamasters]
mayamaster01 ansible_ssh_host=20.10.49.11

[openebs-mayamasters:vars]
ansible_ssh_user="{{ lookup('env','MACHINES_USER_NAME') }}"
ansible_ssh_pass="{{ lookup('env','MACHINES_USER_PASSWORD') }}"
ansible_become_pass="{{ lookup('env','MACHINES_USER_PASSWORD') }}"
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'

[openebs-mayahosts]
mayahost01 ansible_ssh_host=20.10.49.12
mayahost02 ansible_ssh_host=20.10.49.13

[openebs-mayahosts:vars]
ansible_ssh_user="{{ lookup('env','USER_NAME') }}"
ansible_ssh_pass="{{ lookup('env','USER_PASSWORD') }}"
ansible_become_pass="{{ lookup('env','USER_PASSWORD') }}"
ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
```
