#!/bin/bash

# Variables:
machineip=
releasetag=

# Functions:
function get_machine_ip(){
    ifconfig | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | tail -n 2 | head -n 1
}

function install_omm(){
    releaseurl="https://api.github.com/repos/openebs/maya/releases"
    # Update apt and get dependencies
    sudo apt-get update
    sudo apt-get install -y unzip curl wget

    # Install Maya binaries
    if [ -z "$releasetag" ]; then
        wget $(curl -sS $releaseurl | grep "browser_download_url" | awk '{print $2}' | tr -d '"' | head -n 2 | tail -n 1)
    else    
        wget https://github.com/openebs/maya/releases/download/$releasetag/maya-linux_amd64.zip
    fi
    unzip maya-linux_amd64.zip
    sudo mv maya /usr/bin
    rm -rf maya-linux_amd64.zip
}

function setup_omm(){
    maya setup-omm -self-ip=$machineip
}

function show_help() {
    cat << EOF
    Usage : $(basename "$0") --releasetag=[OpenEBS Maya Release Version]
    Installs the OpenEBS Maya Version 
    
    -h|--help                           Display this help and exit.
    -r|--release Maya Release Version   IP of kubemaster to join the cluster.    
EOF
}

function download_specs(){

    specurl="https://api.github.com/repos/openebs/openebs/contents/k8s/demo/specs"
    mapfile -t downloadurls < <(curl -sS $specurl | grep "download_url" | awk '{print $2}' | tr -d '",')
    
    #Create demo directory and download specs
    mkdir -p /home/ubuntu/demo/maya/spec
    cd /home/ubuntu/demo/maya/spec    
    
    length=${#downloadurls[@]}
    for ((i = 0; i != length; i++)); do
        if [ -z "${downloadurls[i]##*hcl*}" ] ;then
            wget "${downloadurls[i]}"
        fi
    done
    
}

# Code:

while :; do
    case $1 in
        -h|-\?|--help)  # Call a "show_help" function to display a synopsis, then exit.
                        show_help
                        exit
                        ;;
        
        -r|--releasetag)  # Takes an option argument, ensuring it has been specified.
                        if [ -n "$2" ]; then
                            releasetag=$2
                            shift
                        else
                            printf 'ERROR: "--releasetag" requires a non-empty option argument.\n' >&2
                            exit 1
                        fi
                        ;;
        
        --releasetag=?*)  # Delete everything up to "=" and assign the remainder.
                        releasetag=${1#*=} 
                        ;;
        
        --releasetag=)    # Handle the case of an empty --masterip=
                        printf 'ERROR: "--releasetag" requires a non-empty option argument.\n' >&2
                        exit 1
                        ;;
        
        --)             # End of all options.
                        shift
                        break
                        ;;
        
        -?*)
                        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
                        ;;

        *)              # Default case: If no more options then break out of the loop.
                        break
    esac
shift
done

#Get the ip of the machine
machineip=`get_machine_ip`

#Install OpenEBS Maya Components
echo Installing OpenEBS on Master...
install_omm

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_omm

#Download the specs for the demo
echo Downloading samples for demo...
download_specs
