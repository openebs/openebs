# Setting Up Jenkins for OpenEBS Continuous Integration(OCI)

  Jenkins® is an open source automation server. With Jenkins, organizations can accelerate the software development process through automation. Jenkins manages and controls development lifecycle processes of all kinds, including build, document, test, package, stage, deployment, static analysis and many more.

  The purpose of this user guide is to provide the user with instructions to set up Jenkins® on a workstation.

## Continuous Integration - Step 1: Setting Up The Build Machine

### How-to - Install Ansible and Jenkins

- Download the _setup-build-machine_ script file from the following URL::

   ```
   wget https://raw.githubusercontent.com/openebs/openebs/master/e2e/jenkins/setup-build-machine.sh
   ```

- Run the script on the workstation with a user having sudo permissions.
- This will install Jenkins and the required packages.
- A user called '_jenkins_' is created when you install Jenkins.

## Continuous Integration - Step 2: Setting Up Jenkins using Web-Interface

- The default way to access the Jenkins server is through a browser, using the URL:

   ```
   http://<jenkins-server>:8080
   ```

- When you open this URL for the first time, you are provided with a path to a file in the server. _/var/lib/jenkins/secrets/initialAdminPassword_.
- This file contains the password for user _admin_.
- Once you log in, it redirects you to a _Getting Started_ page. Click _Install Suggested Plugins_ option.
- You are now prompted to create a new admin user.
- Create a user called _openebs_ providing the required details requested by the _Create First Admin User_ page and click _Save and Finish_.
- A message "_Jenkins is ready!_" is displayed..
- Click _Start using Jenkins_.
- You are now logged in as user _openebs_ and will be able to see your _Dashboard_.

__Note:__

   ```
   By default, the pages in Jenkins do not refresh automatically. To enable it click on the *ENABLE AUTO REFRESH* link on the top right of the page.
   ```

## Continuous Integration - Step 3: Installing Additional Plugins

- On the left side of the _Dashboard_ you have links for managing Jenkins.
- Click _Manage Jenkins->Manage Plugins_.
- On the Plugin Manager page, the following 4 tabs are displayed:
  - Updates
  - Available
  - Installed
  - Advanced
- Click on _Available_ and in the _Filter_ field search and add following 3 plugins.
  - Environment Injector Plugin
  - Hudson Post build task
  - Slack Notification Plugin
- Select _Restart Jenkins when installation is complete and no jobs are running_ to restart Jenkins.

### Configure Slack Plugin Preferences

__Prerequisite:__

```
Jenkins application for Slack must be installed and configured.
```

- Click _Manage Jenkins_.
- Click _Configure System_.
- Scroll to _Global Slack Notifier Settings_.
  - Enter the slack team's team domain in _Team Subdomain_ field.
  - Enter the token provided in the Jenkins application for Slack in _Integration Token_ field.
  - Enter the slack channel details in _Channel_ field.
  - Click _Test Connection_. The slack channel should be getting a notification from Jenkins.
  - If a notification is received then click _Apply_ and _Save_.
  - The configuration for the Slack Plugin is complete.

## Continuous Integration - Step 4: Creating The Jobs

- Click on the _create new jobs_ link in the _Dashboard_.
- Provide a name for the project and select project type as _Freestyle Project_.
- The Job page is divided into 6 categories:
  - General
  - Source Code Management
  - Build Triggers
  - Build Environment
  - Build
  - Post Build Actions
- Click on the '?' symbol for each entry to get its relevant help.

### How-to - Fill the General Category

- The Project name is populated with the name provided for the job.
- Provide a description for the job.
- Select _Github Project_ checkbox.
- Provide the _Project URL_.
  
### How-to - Fill the SCM Category

- Select _Git_ as the repository.
- Provide Repository URL
- Set the Refspec for the repository.
- Click _Apply_. (Do this periodically to save your changes before the session times out)

### How-to - Fill the Build Triggers Category

- Select the _Poll SCM_ checkbox.
- Set the polling schedule for the repository.

### How-to - Fill the Build Environment Category

- Select _Add timestamps to the Console Output_ checkbox.
- Select _Inject environment variables to the build process_ checkbox.
- Provide the relative or absolute path for the _.profile_ file along with the filename.
- Select _Inject passwords to the build as environment variables_ checkbox.
- This option encrypts the environment variables, as a security measure for files getting checked in into the repository.

### How-to - Fill the Build Category

#### Cloning OpenEBS, Installing ARA And Setting Up The Environment

- Click _Add Build Step_ drop-down list and select _Execute Shell_.
- Enter the script below in the script editor provided.

   ```bash
   #!/bin/bash

   if [ ! -d "${JENKINS_HOME}/openebs" ]; then

   # Control will enter here if $DIRECTORY doesn't exist.
   cd ${JENKINS_HOME}
   git clone https://github.com/openebs/openebs.git

   cd ${JENKINS_HOME}/openebs/e2e/ansible/
   ansible-playbook setup-ara.yml
   ansible-playbook -e "run_ci=yes ci_mode=hyperconverged build_type=quick" setup-env.yml

   echo vagrant up
   vagrant up
   ansible-playbook -e "build_type=quick" ci.yml
   else

   cd ${JENKINS_HOME}/openebs/e2e/ansible/
   ansible-playbook -e "run_ci=yes ci_mode=hyperconverged build_type=quick" setup-env.yml

   echo vagrant up
   vagrant up
   ansible-playbook -e "build_type=quick" ci.yml
   fi
   ```

- The script clones _openebs_ repository for running Ansible Playbooks.
- The script also sets up ARA for reporting.
- Finally it runs the _CI.yml_ to perform _Continuous Integration_ of _OpenEBS_ modules.

### How-to - Fill the Post Build Actions Category

#### Adding Post Build Task And Slack Notifications

- Click _Add post-build action_ drop-down list and select _Post build task_ plugin.
  - In the _Log Text_ textbox enter text: _vagrant up_
  - Enter the script below in the script editor provided.

   ```bash
   #!/bin/bash

   cd ${JENKINS_HOME}/openebs/e2e/ansible/
   vagrant destroy -f

   # The below depends on the mode of deployment(dedicated/hyperconverged)
   ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R 172.28.128.31
   ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R 172.28.128.32
   ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R 172.28.128.33
   ```

  - Select _Escalate script execution status to job status_.

- Click _Add post-build action_ drop-down list and select _Post build task_ plugin.
  - In the _Log Text_ textbox enter text: _(failed=)(\d*[1-9]\d*)_
  - Enter the below script in the provided script editor.
  
   ```bash
   #!/bin/bash
   exit 1
   ```

  - Select _Escalate script execution status to job status_.

- Click *Add post-build action* drop-down list and select *Slack Notifications* plugin.
  - Select _Notify Build Start_.
  - Select _Notify Failure_.
  - Select _Notify Success_.
  - Select _Notification message includes:_ and in the drop-down list select _commit list with authours and titles_.