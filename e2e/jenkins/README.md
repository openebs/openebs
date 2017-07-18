# Setting Up Jenkins for OpenEBS Continuous Integration(OCI)

  Jenkins® is an open source automation server. With Jenkins, organizations can accelerate the software development process through automation. Jenkins manages and controls development lifecycle processes of all kinds, including build, document, test, package, stage, deployment, static analysis and many more.

  The purpose of this user guide is to provide the user with instructions to set up Jenkins® on a workstation.

## Continuous Integration - Step 1: Setting Up The Build Machine

### How-to - Install Ansible and Jenkins

 - Download the setup-build-machine.sh script from:
   ```
   wget https://raw.githubusercontent.com/openebs/openebs/master/e2e/jenkins/setup-build-machine.sh
   ```
 - Run the script on the workstation with a user having sudo permissions.
 - This will install jenkins and required packages.
 - A user called '*jenkins*' is created along with the jenkins installation.

## Continuous Integration - Step 2: Setting Up Jenkins using Web-Interface

- The default way to access the jenkins server is through a browser, using the URL
```
http://<jenkins-server>:8080
```
- The first time this URL is opened, the user is provided with a path to a file in the server */var/lib/jenkins/secrets/initialAdminPassword*. 
- This file contains the password for user *admin*.
- Once logged in it redirects to a *Getting Started* page. Click on *Install Suggested Plugins* option.
- The user is now prompted to create a new admin user.
- Create a user called *openebs* providing the essential details requested by the *Create First Admin User* page and click on *Save and Finish*.
- You should be seeing a message which says *Jenkins is ready!*
- Click on *Start using Jenkins*
- You will logged in as user *openebs* automatically and will be able to see his *Dashboard*.

Note:
```
By default the pages in Jenkins do not refresh automatically, to enable it click on the *ENABLE AUTO REFRESH* link on the top right of the page. 
```

## Continuous Integration - Step 3: Installing Additional Plugins

- On the left side of the *Dashboard* you have links for managing Jenkins.
- Click on *Manage Jenkins->Manage Plugins*, you are now in the Plugin Manager page.
- You should be able to see a page with 4 tabs(*Updates-Available-Installed-Advanced*).
- Click on the *Available* tab and in the *Filter* textbox search and add following 2 plugins one by one.
  - Environment Injector Plugin
  - Hudson Post build task
  - Slack Notification Plugin
- Select the *Restart Jenkins when installation is complete and no jobs are running* to restart jenkins.


## Continuous Integration - Step 6: Creating The Jobs

- Click on the *create new jobs* link in the *Dashboard*.
- Provide a name for the project and select project type as *Freestyle Project*.
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
  - Select *Github Project* checkbox.
  - Provide the *Project URL*.
  
  ### How-to - Fill the SCM Category

  - Select *Git* as the repository.
  - Provide Repository URL
  - Set the Refspec for the repository.
  - Click on Apply button - (Do this periodically to save your changes before the session times out)

  ### How-to - Fill the Build Triggers Category

  - Select the *Poll SCM* checkbox.
  - Set the polling schedule for the repository.

  ### How-to - Fill the Build Environment Category

  - Select *Add timestamps to the Console Output* checkbox.
  - Select *Inject environment variables to the build process* checkbox.
  - Provide the relative or absolute path for the *.profile* file along with the filename.
  - Select *Inject passwords to the build as environment variables* checkbox.
  - This option encrypts the environment variables, as a security measure for files getting checked in into the repository.

  ### How-to - Fill the Build Category

  #### Cloning OpenEBS, Installing ARA And Setting Up The Environment

  - Click on *Add Build Step* combobox and select *Execute Shell*.
  - Enter the below script in the provided shell editor.
  ```
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
  ansible-playbook -e "build_type=normal" ci.yml
  else

  cd ${JENKINS_HOME}/openebs/e2e/ansible/
  ansible-playbook -e "run_ci=yes ci_mode=hyperconverged build_type=quick" setup-env.yml

  echo vagrant up
  vagrant up
  ansible-playbook -e "build_type=quick" ci.yml
  fi
  ```

  - The above script clones *openebs* repository for running Ansible Playbooks.
  - The script also sets up ARA for reporting.
  - Finally it runs the *CI.yml* to perform *Continuous Integration* of *OpenEBS* modules

  ### How-to - Fill the Post Build Actions Category

  #### Adding Post Build Task And Slack Notifications

  - Click on the *Add post-build action* combobox and select *Post build task* plugin.
  - In the *Log Text* textbox type *vagrant up*.
  - Enter the below script in the provided editor.
  ```
  #!/bin/bash

  cd ${JENKINS_HOME}/openebs/e2e/ansible/
  vagrant destroy -f

  # The below depends on the mode of deployment(dedicated/hyperconverged)
  ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R 172.28.128.31
  ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R 172.28.128.32
  ssh-keygen -f "/var/lib/jenkins/.ssh/known_hosts" -R 172.28.128.33
  ```
  - Click on the *Add post-build action* combobox and select *Slack Notifications* plugin.
  - Select the type of notifications you want the build to send to Slack.