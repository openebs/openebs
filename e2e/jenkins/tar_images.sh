#!/bin/bash

#############################################################################
# This is a script that will be run periodically as part of a cronjob on the 
# Jenkins master (build machine) to create docker image tarballs for the e2e
# test images. The script checks for presence of the versioned image tarballs
# and if the desired version is not present, fetches the image and creates the 
# tarball. It uses the setup-test-images ansible role to perform these tasks.
#
# These tarfiles are used by the load-test-images ansible role to load the 
# images into the test VMs created as part of the CI test run.
#############################################################################

source ~/.profile

# file touched by the jenkins job to indicate run in progress
file=ci.running

# log file path
log=~/openebs/tar_status.log

# message definitions
no_run_msg="##### CI RUN IN PROGRESS, WON'T ATTEMPT TEST IMAGE UPDATES #####"
run_msg="##### RUNNING PLAYBOOK TO PEROFRM IMAGE CHECK #####"
error_msg="##### ERRORS DURING PLAYBOOK RUN, CHECK ARA LOGS #####"
success_msg="##### PLAYBOOK COMPLETED SUCCESSFULLY #####"

# look for file indicating ongoing CI job, exit if present
if [ -f "$file" ]; then
    echo $no_run_msg | awk '{ print strftime("%c:"),$0; fflush();}' >> $log
    exit
fi

# invoke the setup-images.yml playbook
echo $run_msg | awk '{ print strftime("%c:"),$0; fflush();}' >> $log
cd ~/openebs/e2e/ansible && ansible-playbook setup-images.yml 2>&1 >> $log 

# log failed playbook runs
retcode=$?

if [ $retcode -ne 0 ]
then
    echo $error_msg | awk '{ print strftime("%c:"),$0; fflush();}' >> $log
    echo $retcode >> $log
else 
    echo $success_msg | awk '{ print strftime("%c:"),$0; fflush();}' >> $log
fi
