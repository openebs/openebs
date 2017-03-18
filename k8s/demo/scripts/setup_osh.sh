#!/bin/bash

#Variables:
machineip="0.0.0.0"
hostname=`hostname`
masterhostname=""
masterip=""
releasetag="0.0.1.0"
usage="Usage : $(basename "$0") -i Master_IPAddress -r Release_Version"

#Functions:
function get_machine_ip(){
    ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1
}

function install_osh(){
    # Update apt and get dependencies
    sudo apt-get update
    sudo apt-get install -y unzip curl wget

    # Install Maya binaries
    wget https://github.com/openebs/maya/releases/download/$releasetag/maya-linux_amd64.zip
    unzip maya-linux_amd64.zip
    sudo mv maya /usr/bin
    rm -rf maya-linux_amd64.zip
}

function setup_osh(){
    maya setup-osh -self-ip=$machineip -omm-ips=$masterip
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

while getopts ":i:r:" options; do
    case $options in        
        i)  masterip=$OPTARG
            ;;        
        r)  releasetag=$OPTARG        
            ;;    
        \?) echo $usage
            exit 1;;
        *)  echo $usage
            exit 1;;
    esac
done

if [ "x" != "x$masterip" ]; then
    if [ "x" == "x$releasetag" ]; then
        echo "-i [option] requires -r [option]"
        echo $usage
        exit
    fi
fi
if [ "x" != "x$releasetag" ]; then
    if [ "x" == "x$masterip" ]; then
        echo "-r [option] requires -i [option]"
        echo $usage
        exit
    fi
fi

#Get the ip of the machine
machineip=`get_machine_ip`

#Install OpenEBS Maya Components
echo Installing OpenEBS on Host...
install_osh

#Join the Cluster
echo Setting up the Host using IPAddress: $machineip
setup_osh
