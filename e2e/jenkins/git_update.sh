#!/bin/bash

###################################################################################
# This script is invoked by the git_monitor.sh script to merge latest automation
# code into the Jenkins master and run the CI suite. It uses env variables in order 
# to store jenkins related info needed to trigger the CI job.These should to be set 
# prior to scheduling the cron job. 
#
# For ex:
# 
# export JENKINS_MASTER_IP="20.10.30.253"
# export JENKINS_PORT="8080" 
# export JENKINS_USER="openebs"
# export JENKINS_PASSWORD="openebs"
# export JENKINS_USER_API_KEY="41d9e9efee80939f116fd77e5e1cd736"
# export JOB_NAME="jiva"
# export BUILD_TOKEN="openebstestbuild"
#
###################################################################################

# source the user .profile to load the env variables
source ~/.profile 

# file touched by the jenkins job to indicate run in progress
file=ci.running

# construct command to obtain jenkins crumb (in lieu of CSRF protection)
GET_CRUMB="wget -q --auth-no-challenge --user $JENKINS_USER --password $JENKINS_PASSWORD \
--output-document - 'http://$JENKINS_MASTER_IP:$JENKINS_PORT\
/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)'"

# obtain the jenkins crumb
CRUMB=`eval $GET_CRUMB`

# url to trigger jenkins CI job 
ci_trigger_url="curl -f -X POST -H $CRUMB --user $JENKINS_USER:$JENKINS_USER_API_KEY \
http://$JENKINS_MASTER_IP:$JENKINS_PORT/job/$JOB_NAME/build?token=$BUILD_TOKEN"

# look for file indicating ongoing CI job, exit if present 
if [ -f "$file" ]; then
    echo "##### CI RUN IN PROGRESS, WON'T POLL FOR E2E UPDATES #####"
    exit
fi

echo "##### POLL FOR UPDATES TO THE CI FRAMEWORK #####"

# perform git stash to store local changes separately and revert to cloned state
git stash

# perform git pull to fetch & merge updated files from repository
git pull

# get changes in e2e, if any
content=`git diff master@{1} master --name-only e2e` 

# trigger/schedule a CI run if e2e/Ansible is updated 
if ! [ -z "$content" ]
then
    echo $content; echo "Triggering CI..."
    eval $ci_trigger_url > /dev/null 2>&1
    retcode=$? 
    if [ $retcode -ne 0 ] 
    then
        echo "Failed to trigger CI, found non-zero exit status ($retcode)"
        exit
    else
        echo "Started CI suite"
    fi
else
    echo "No changes to e2e, no action taken"
fi


