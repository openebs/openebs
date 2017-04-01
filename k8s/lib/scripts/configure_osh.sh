#!/bin/bash

# Variables:
machineip=
masterip=
releasetag=

# Functions:
function get_machine_ip(){
    ifconfig \
    | grep -oP "inet addr:\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" \
    | grep -oP "\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}" | sort \
    | tail -n 1 | head -n 1
}

function setup_osh(){
    maya setup-osh -self-ip=$machineip -omm-ips=$masterip
}

function show_help() {
    cat << EOF
    Usage : $(basename "$0") --masterip=[OpenEBS Maya MasterIP]
    Installs the OpenEBS Maya Version 
    
    -h|--help       Display this help and exit.
    -r|--masterip   Maya MasterIP.    
EOF
}

# Code:
 
if (($# == 0)); then
    show_help
    exit 2
fi

while :; do
    case $1 in
        -h|-\?|--help)  # Call a "show_help" function to 
                        # display a synopsis, then exit.
                        show_help
                        exit
                        ;;
        
        -i|--masterip)  # Takes an option argument, 
                        # ensuring it has been specified.
                        if [ -n "$2" ]; then
                            masterip=$2
                            shift
                        else
                            printf 'ERROR: "--masterip" requires \
                            a non-empty option argument.\n' >&2
                            exit 1
                        fi
                        ;;
        
        --masterip=?*)  # Delete everything up to "=" 
                        # and assign the remainder.
                        masterip=${1#*=} 
                        ;;
        
        --masterip=)    # Handle the case of an empty --masterip=
                        printf 'ERROR: "--masterip" requires \
                        a non-empty option argument.\n' >&2
                        exit 1
                        ;;
 
        --)             # End of all options.
                        shift
                        break
                        ;;
        
        -?*)
                        printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
                        ;;

        *)              # Default case: If no more options 
                        # then break out of the loop.
                        break
    esac
shift
done

if [ -z "$masterip" ]; then
    echo "MasterIP is mandatory."
    show_help
    exit    
fi

#Get the ip of the machine
machineip=`get_machine_ip`

#Join the Cluster
echo Setting up the Host using IPAddress: $machineip
setup_osh