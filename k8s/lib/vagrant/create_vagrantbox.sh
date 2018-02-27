#!/bin/bash
#set -x
kubeversion=
distribution=
docker_version=
kuberegex='^[1-9][.][0-9][0-9]?[.][0-9][0-9]?$'
kuberegex_cni='^1[.][6-8][.][0-9][0-9]?$'

debpackageurl="https://packages.cloud.google.com/apt/dists/kubernetes-xenial/main/binary-amd64/Packages"
rpmpackageurl="https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64/repodata/primary.xml"

function show_help() {
    cat << EOF
Usage: $(basename "$0") --kube-version=<Kubernetes Version> [--base-os=<Linux Distribution>]
Creates a vagrant box with the provided Kubernetes version.

Options and arguments for the tool.    
--help                    Display this help and exit.
--kube-version            Kubemaster Version to be used for the cluster. Example:- 1.8.0, 1.8.5, 1.9.0.
--base-os                 Linux Distribution to be used for creating the vagrant box. Supported:- ubuntu & centos.
                          Defaults to "ubuntu"
EOF
}

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
        
        --kube-version) # Takes an option argument, 
                        # ensuring it has been specified.
                        if [ -n "$2" ]; then

                           if [[ "$2" =~ $kuberegex ]]; then
	                           kubeversion=$2
                           else
	                           printf 'ERROR: Invalid Kubernetes Version.\n' >&2
                               show_help
                               exit 1
                           fi
                            
                            shift
                        else
                            printf 'ERROR: "--kube-version" requires a non-empty option argument.\n\n' >&2
                            show_help
                            exit 1
                        fi
                        ;;
        
        --kube-version=?*)  # Delete everything up to "=" 
                        # and assign the remainder.
                        if [[ "${1#*=}" =~ $kuberegex ]]; then
	                           kubeversion=${1#*=}
                        else
	                           printf 'ERROR: Invalid Kubernetes Version.\n\n' >&2
                               show_help
                               exit 1
                        fi                         
                        ;;
        
        --kube-version=)    # Handle the case of an empty --masterip=
                        printf 'ERROR: "--kube-version" requires a non-empty option argument.\n\n' >&2
                        show_help
                        exit 1
                        ;;

        --base-os)     # Takes an option argument, 
                        # ensuring it has been specified.
                        if [ -n "$2" ]; then                             
                            distribution="$(echo $2 | tr '[:upper:]' '[:lower:]')"                            
                            shift
                        else
                            printf 'ERROR: "--base-os" requires a non-empty option argument.\n' >&2
                            show_help
                            exit 1
                        fi
                        ;;
        
        --base-os=?*)     # Delete everything up to "=" 
                        # and assign the remainder.
                        if [ -n "${1#*=}" ]; then
                           distribution="$(echo ${1#*=} | tr '[:upper:]' '[:lower:]')"                           
                           shift 
                        else
                            printf 'ERROR: "--base-os" requires a non-empty option argument.\n' >&2
                            show_help
                            exit 1
                        fi 
                        ;;
        
        --base-os=)       # Handle the case of an empty --base-os=
                        distribution="ubuntu"                        
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

if [ -z "$kubeversion" ]; then
    echo "Kubernetes version is mandatory."
    show_help
    exit    
fi

if [ -z "$distribution" ]; then
    echo Defaulting to Ubuntu Distro.
    distribution="ubuntu"    
fi

function fetch_k8s_scripts(){
    mkdir -p workdir/scripts/k8s/    
    cp ../scripts/configure_k8s_master.sh workdir/scripts/k8s/
    sed -i "s/.*kubeversion=.*/kubeversion=v${kubeversion}/g" workdir/scripts/k8s/configure_k8s_master.sh


    cp boxes/ubuntu-xenial/prepare_network.sh workdir/scripts/k8s
    cp ../scripts/configure_k8s_host.sh workdir/scripts/k8s/    
    cp ../scripts/configure_k8s_cred.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_dashboard.sh workdir/scripts/k8s/
    cp ../scripts/configure_k8s_cni.sh workdir/scripts/k8s/
       
}

function fetch_specs(){
    mkdir -p workdir/specs
    cp ../../demo/specs/demo-vdbench-openebs.yaml workdir/specs/
    cp ../../demo/specs/demo-fio-openebs.yaml workdir/specs/
}

function fetch_k8s_debpkgs(){
    mkdir -p workdir/debpkgs
    
    mapfile -t packagedownloadurls < <(curl -sS $debpackageurl \
    | grep _$kubeversion | awk '{print $2}' \
    | cut -d '/' -f2)

    length=${#packagedownloadurls[@]}

    if [ "$length" -eq 0 ]; then
       echo "Unable to download packages for the specified Version."
       echo "Run the script again. If the problem persists try with a different Version."
       cleanup
       exit 
    fi
    
    for ((i = 0; i != length; i++)); do    
        wget "https://packages.cloud.google.com/apt/pool/${packagedownloadurls[i]}" -P workdir/debpkgs    
    done

    [[ $kubeversion =~ $kuberegex_cni ]]

    if [[ $? -eq 1 ]]; then
        wget https://packages.cloud.google.com/apt/pool/kubernetes-cni_0.6.0-00_amd64_43460dd3c97073851f84b32f5e8eebdc84fadedb5d5a00d1fc6872f30a4dd42c.deb \
    -P workdir/debpkgs
    else
        wget https://packages.cloud.google.com/apt/pool/kubernetes-cni_0.5.1-00_amd64_08cbe5c42366ec3184cc91a4353f6e066f2d7325b4db1cb4f87c7dcc8c0eb620.deb \
    -P workdir/debpkgs
    fi
}

function fetch_k8s_rpmpkgs(){
    mkdir -p workdir/rpmpkgs

    mapfile -t packagedownloadurls < <(curl -sS  $rpmpackageurl \
    | grep -- -$kubeversion | grep "location href" \
    | awk '{print $2}' | cut -d '/' -f4 | cut -d '"' -f1)

    
    length=${#packagedownloadurls[@]}

    if [ "$length" -eq 0 ]; then
       echo "Unable to download packages for the specified Version."
       echo "Run the script again. If the problem persists try with a different Version."
       cleanup
       exit 
    fi
    
    for ((i = 0; i != length; i++)); do    
        wget "https://packages.cloud.google.com/yum/pool/${packagedownloadurls[i]}" -P workdir/rpmpkgs    
    done

    [[ $kubeversion =~ $kuberegex_cni ]]

    if [[ $? -eq 1 ]]; then

        wget https://packages.cloud.google.com/yum/pool/fe33057ffe95bfae65e2f269e1b05e99308853176e24a4d027bc082b471a07c0-kubernetes-cni-0.6.0-0.x86_64.rpm \
    -P workdir/rpmpkgs
    else

        wget https://packages.cloud.google.com/yum/pool/e7a4403227dd24036f3b0615663a371c4e07a95be5fee53505e647fd8ae58aa6-kubernetes-cni-0.5.1-0.x86_64.rpm \
    -P workdir/rpmpkgs        

    fi
}

function cleanup(){
    rm -rf workdir
}

echo Download Kubernetes Packages
if [ "$distribution" = "ubuntu" ]; then
   echo Choose the Docker installation:
   select docker in "Docker CE" "Docker Engine"
   do
        case $docker in 
        "Docker CE"|"Docker Engine")   
                break
                ;;
        *)
                echo "Invalid area" 
                ;;
        esac
   done

   if [ "$docker" = "Docker CE" ]; then
      docker_version="docker-ce"
   else
      docker_version="docker-cs"
   fi   
   fetch_k8s_debpkgs
else
   docker_version="docker-ce"
   fetch_k8s_rpmpkgs
fi

echo Gathering all the K8s configure scripts to be package
fetch_k8s_scripts

echo Gathering sample k8s specs
fetch_specs

echo Launch VM

KUBE_VERSION=${kubeversion} DISTRIBUTION=${distribution} DOCKER=${docker_version} vagrant up
vagrant package --output workdir/kubernetes-${kubeversion}-${distribution}.box

echo Test the new box
vagrant box add --name openebs/k8s-test-box --force workdir/kubernetes-${kubeversion}-${distribution}.box 
mkdir workdir/test 
currdir=`pwd`
cp test/k8s/Vagrantfile workdir/test/
cd workdir/test;

if [ "$distribution" = "centos" ]; then
   sudo sed -i 's/vmCfg.ssh.username = "ubuntu"/vmCfg.ssh.username = "vagrant"/g' Vagrantfile
   sudo sed -i 's/echo "ubuntu:ubuntu"/echo "vagrant:vagrant"/g' Vagrantfile
fi   
vagrant up
#vagrant destroy -f
#vagrant box remove openebs/k8s-test-box
#cd $currdir

echo Destroy the default vm
#vagrant destroy default

echo Clear working directory
#cleanup


