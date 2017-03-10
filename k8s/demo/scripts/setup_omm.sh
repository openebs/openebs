#!/bin/bash

#Variables:
machineip="0.0.0.0"
hostname=`hostname`
releasetag="0.0.5"
usage="Usage : $(basename "$0") -r Release_Version"

#Functions:
function get_machine_ip(){
    ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1
}

function install_omm(){
    # Update apt and get dependencies
    sudo apt-get update
    sudo apt-get install -y unzip curl wget

    # Install Maya binaries
    wget https://github.com/openebs/maya/releases/download/$releasetag/maya-linux_amd64.zip
    unzip maya-linux_amd64.zip
    sudo mv maya /usr/bin
    rm -rf maya-linux_amd64.zip
}

function setup_omm(){
    maya setup-omm -self-ip=$machineip
}

#Code
#Code:
#Check whether we recieved the release version else show usage.
# Reset if getopts was used previously
OPTIND=1 
if (($# == 0)); then
    echo $usage
    exit 2
fi

while getopts ":r:" options; do
    case $options in
        r)  releasetag=$OPTARG
            ;;
        \?) echo $usage
            exit 1;;
        *)  echo $usage
            exit 1;;
    esac
done

if [ "x" == "x$releasetag" ]; then
     echo "requires -r [option]"
     exit
fi

#Get the ip of the machine
machineip=`get_machine_ip`

#Install OpenEBS Maya Components
echo Installing OpenEBS on Master...
install_omm

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_omm
