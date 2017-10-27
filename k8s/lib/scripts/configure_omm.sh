#!/bin/bash

# Variables:
machineip=

# Functions:
function get_machine_ip(){
    ifconfig \
    | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" \
    | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | sort \
    | tail -n 1 | head -n 1
}

function setup_omm(){
    maya setup-omm -self-ip=$machineip
}

#Get the ip of the machine
machineip=`get_machine_ip`

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_omm