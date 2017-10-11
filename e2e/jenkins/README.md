# Setting Up Jenkins for OpenEBS Continuous Integration(OCI)

  Jenkins® is an open source automation server. With Jenkins, organizations can accelerate the software development process through automation. Jenkins manages and controls development lifecycle processes of all kinds, including build, document, test, package, stage, deployment, static analysis and many more.

  The purpose of this user guide is to provide the user with instructions to set up Jenkins® on a workstation.

## Continuous Integration - Step 1: Setting Up The Build Machine

### How-to - Install Ansible and Jenkins

- Download the script file _setup-build-machine_ from:

   ```
   wget https://raw.githubusercontent.com/openebs/openebs/master/e2e/jenkins/setup-build-machine.sh
   ```

- Run the script on the workstation with a user having sudo permissions.
- This will install jenkins and required packages.
- A user called '_jenkins_' is created along with the jenkins installation.

## Continuous Integration - Step 2: Setting Up Jenkins using Web-Interface

- The default way to access the jenkins server is through a browser, using the URL

   ```
   http://<jenkins-server>:8080
   ```

- The first time this URL is opened, the user is provided with a path to a file in the server _/var/lib/jenkins/secrets/initialAdminPassword_.
- This file contains the password for user _admin_.
- Once logged in it redirects to a _Getting Started_ page. Click on _Install Suggested Plugins_ option.
- The user is now prompted to create a new admin user.
- Create a user called _openebs_ providing the essential details requested by the _Create First Admin User_ page and click on _Save and Finish_.
- You should be seeing a message which says _Jenkins is ready!_
- Click on _Start using Jenkins_.
- You will logged in as user _openebs_ automatically and will be able to see his _Dashboard_.

__Note:__

   ```
   By default the pages in Jenkins do not refresh automatically, to enable it click on the *ENABLE AUTO REFRESH* link on the top right of the page.
   ```

## Continuous Integration - Step 3: Installing Additional Plugins

- On the left side of the _Dashboard_ you have links for managing Jenkins.
- Click on _Manage Jenkins->Manage Plugins_, you are now in the _Plugin Manager_ page.
- You should be able to see a page with 4 tabs(_Updates-Available-Installed-Advanced_).
- Click on the _Available_ tab and in the _Filter_ textbox search and add following 3 plugins one by one.
  - Environment Injector Plugin
  - Hudson Post build task
  - Slack Notification Plugin
- Select the _Restart Jenkins when installation is complete and no jobs are running_ to restart jenkins.

### Configure Slack Plugin Preferences

__Note:__

```
It is a prerequisite that the Jenkins app for Slack is already installed and configured.
```

- Click on _Manage Jenkins_.
- Click on _Configure System_.
- Scroll to _Global Slack Notifier Settings_.
  - Enter the slack team's team domain in _Team Subdomain_
  - Enter the token provided in the Jenkins app in _Integration Token_.
  - Enter the slack channel details in _Channel_.
  - Click on _Test Connection_. The slack should be getting a notification from Jenkins.
  - If a notifications is recieved then click on _Apply_ and then on _Save_.
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
- Click on Apply button - (Do this periodically to save your changes before the session times out)

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

- Click on _Add Build Step_ combobox and select _Execute Shell_.
- Enter the below script in the provided shell editor.

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

- The above script clones _openebs_ repository for running Ansible Playbooks.
- The script also sets up ARA for reporting.
- Finally it runs the _CI.yml_ to perform _Continuous Integration_ of _OpenEBS_ modules

### How-to - Fill the Post Build Actions Category

#### Adding Post Build Task And Slack Notifications

- Click on the _Add post-build action_ combobox and select _Post build task_ plugin.
  - In the _Log Text_ textbox enter text: _vagrant up_.
  - Enter the below script in the provided script editor.

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

- Click on the _Add post-build action_ combobox and select _Post build task_ plugin.
  - In the _Log Text_ textbox enter text: _(failed=)(\d*[1-9]\d*)_.
  - Enter the below script in the provided script editor.
  
   ```bash
   #!/bin/bash
   exit 1
   ```

  - Select _Escalate script execution status to job status_.

- Click on the *Add post-build action* combobox and select *Slack Notifications* plugin.
  - Select _Notify Build Start_.
  - Select _Notify Failure_.
  - Select _Notify Success_.
  - Select _Notification message includes:_ and in the combobox select _commit list with authours and titles_.