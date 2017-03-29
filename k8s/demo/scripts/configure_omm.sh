#!/bin/bash

# Variables:
machineip=
releasetag=

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

function show_help() {
    cat << EOF
    Usage : $(basename "$0") --releasetag=[OpenEBS Maya Release Version]
    Installs the OpenEBS Maya Version 
    
    -h|--help                           Display this help and exit.
    -r|--release Maya Release Version   Maya Release Version to install.    
EOF
}

# Code:

while :; do
    case $1 in
        -h|-\?|--help)  # Call a "show_help" function to 
                        # display a synopsis, then exit.
                        show_help
                        exit
                        ;;
        
        -r|--releasetag)  # Takes an option argument, 
                          # ensuring it has been specified.
                        if [ -n "$2" ]; then
                            releasetag=$2
                            shift
                        else
                            printf 'ERROR: "\--releasetag" requires \
                            a non-empty option argument.\n' >&2
                            exit 1
                        fi
                        ;;
        
        --releasetag=?*)  # Delete everything up to "=" 
                          # and assign the remainder.
                        releasetag=${1#*=} 
                        ;;
        
        --releasetag=)    # Handle the case of an empty --masterip=
                        printf 'ERROR: "--releasetag" requires \
                        a non-empty option argument.\n' >&2
                        exit 1
                        ;;
        
        --)             # End of all options.
                        shift
                        break
                        ;;
        
        -?*)
                        printf 'WARN: Unknown option \
                        (ignored): %s\n' "$1" >&2
                        ;;

        *)              # Default case: If no more options then 
                        # break out of the loop.
                        break
    esac
shift
done

#Get the ip of the machine
machineip=`get_machine_ip`

#Create the Cluster
echo Setting up the Master using IPAddress: $machineip
setup_omm