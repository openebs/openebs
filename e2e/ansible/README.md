# ANSIBLE BASED CI-CD FRAMEWORK FOR OPENEBS
-------------------------------------------

## PURPOSE

This project aims to provide an automated deployment & test framework for OpenEBS 
using the popular provisioning & configuration management tool Ansible,while using 
python & shell scripts for auxiliary purposes. This is intended to facilitate quick 
validation of commits made into openebs repos and keep it free of regression issues.

In its current form, this project performs an automated setup of OpenEBS from a client
machine - including orchestration engine Maya & storage node cluster, spawns a jiva 
volume container on the node and runs an FIO workload on block storage after consuming 
it into a test container. It is expected to evolve to provide more setup & configuration
options and include a greater number of test scenarios.

### Ansible 

#### Why Ansible

Ansible works in an agentless mode (though it needs python & SSH!) to get tasks 
executed on multiple hosts simultaneously. It has a rich set of inbuilt modules 
which cover most of the configuration and deployment steps associated with 
projects like OpenEBS, with options to execute shell commands/run scripts in cases
where desired modules are not present. Ansible also supports integration with 
custom plugins for a wide variety of functions. Add to it the idempotent nature 
of the task execution, and you have a powerful tool for both CI/CD as well as 
standalone automation runs.

#### File extensions in Ansible

Ansible uses YAML because it is easier for humans to read and write than other 
common data formats like XML or JSON. YAML is the format of Ansible's 
important components, such as playbooks & variable definition files. Ansible also 
uses .cfg files to store host details (called inventory) and define its own functional 
parameters (ansible.cfg) 

#### How it works 

Ansible runs a set of "plays" which are a collection of "tasks" - on a group of 
hosts defined in the inventory (typically, a file called "hosts"). A "playbook" 
consists of multiple such plays to be executed. Ansible "roles" are reusable 
abstractions which can be created based on an overall function performed by a set 
of tasks, and can be included into playbooks.Each role has a default structure with
vars,defaults,tasks,meta,handler folders, with each containing a "main.yml" file. 
The vars & defaults folders consist of variables used by the tasks in the role. 
The meta folder contains role dependencies, i.e., tasks to be run before running 
current role tasks.The handler takes care of service handling and is invoked by the 
"notify" keyword inside tasks.

### DIRECTORY LAYOUT OF THE CI-CD PROJECT 

The openebs Ansible project tree is shown below.

```
ansible
|
|
|__inventory/machines.in, hosts
|    |__group_vars    {all.yml}
|   
|__roles 
|    |
|    |__prerequisites {defaults/main.yml, tasks/main.yml}
|    |__vagrant       {defaults/main.yml, meta/main.yml, tasks/main.yml}
|    |__inventory     {defaults/main.yml, meta/main.yml, tasks/main.yml}
|    |__common        {defaults/main.yml, meta/main.yml, tasks/main.yml}
|    |__master        {defaults/main.yml, meta/main.yml, tasks/main.yml, handlers/main.yml}
|    |__hosts         {meta/main.yml, tasks/main.yml} 
|    |__volume        {defaults/main.yml, tasks/main.yml}
|    |__localhost     {defaults/main.yml, tasks/main.yml} 
|    |__fio           {defaults/main.yml, tasks/main.yml} 
|    |__cleanup       {defaults/main.yml, tasks/main.yml}
|
|__plugins
|    |__callback      {openebs.py}
|
|__files              {utils.py, generate-inventory.py}
|
|__{Vagrantfile}
|
|__{ansible.cfg}
|
|__{site.yml}

```
A brief outline of the functions associated with above components is described below : 

#### inventory :
  This is the default directory that holds the hosts file  
- machines.in : Input file for inventory file generation 
- hosts : Default inventory file referred to in the plays
- group_Vars/all.yml : Contains global variables for playbook run

#### roles : 
  Contains ansible roles for openebs cluster setup and I/O run
- prerequisites : Installs python packages necessary for inventory generation
- inventory : Generates the hosts file based on entries in machines.in. 
- common : Installs apt packages common to Maya Server & Storage Node cluster
- master : Installs & configures maya server
- hosts : Installs & configures openebs storage hosts
- vagrant : Makes some config changes in maya server & node setup if machines are vagrant VMs
- volume : Creates a volume according to input parameters in all.yml
- localhost : Configures the client machine to run FIO container
- fio : Runs fio profile in a test container after mounting block storage (on client)
- cleanup : Tear down iSCSI sessions & destroys volume on the storage nodes

#### plugins :
   Contains custom plugins that can be integrated into Ansible. 
   Ex: stdout callback
   
#### files :
   Contains auxiliary files such as images, scripts, etc., which may be used during a 
   playbook run. Includes python scripts to generate inventory file. 
   
#### Vagrantfile : 
   Vagrantfile for pre-packaged linux VM bring up

#### ansible.cfg : 
   Custom ansible configuration file for openebs

#### site.yml : 
   The master playbook which executes all roles
   
### INSTALLATION

The pre-requisites include availability of at-least four linux machines (VMs OR bare-metal boxes,
to be used as client, Maya-master server, at least two OpenEBS storage hosts respectively) with 
basic development packages, SSH service & ansible (version >= 2.3) installed (ansible in turn needs 
python-minimal on the boxes as a pre-requisite). 

The ansible based CI-CD framework for openebs can be installed via a git clone of the elves 
repository (openebs/elves/ansible) into the client machine 

`git clone https://github.com/openebs/elves.git`

### USAGE

- Edit the machines.in in the ansible/inventory folder to reflect the correct IP addresses
- Ensure that the env variables for the username and passwords of respective machines are set
- Edit the all.yml to reflect the desired volume properties & network cidr for volume container
- Trigger the ansible playbook run using command 

`ansible-playbook site.yml` 

The following actions are carried out upon running the playbook : 

- Client machine is setup to generate inventory file
- The inventory file (hosts) is updated with latest info from the machines.in input file
- Maya server is setup
- Storage hosts are setup
- volume is created
- Container to launch FIO is instantiated
- Cleanup is performed post user confirmation

### LIMITATIONS

Currently, the playbooks are written to work with Ubuntu hosts. They will be enhanced to work on other
linux flavours soon.

### SWITCHES AND LATCHES

- Use `-v` flag while running the playbook to enable verbose logging. 
- Use ansible tags to run/skip tasks in the roles

### CONTRIBUTIONS

If you'd like to contribute, please fork the repository and use a feature branch. 
Pull requests are warmly welcome."








  

















