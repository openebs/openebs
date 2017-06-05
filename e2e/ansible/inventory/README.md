# Ansible Inventory 
-------------------

This is the ansible default directory that holds the ```hosts`` file, which contains details of the host machines on which 
ansible tasks are executed.

A brief description of the files in this directory is given below : 

- machines.in : Input file used by the pre-requisites.yml playbook to generate the ansible 'hosts' file
- hosts : Default inventory file referred to in the playbooks
- group_Vars/all.yml : Contains global variables for ansible playbooks 
