#!/usr/bin/env python
import os
import sys
from utils import sshToOtherClient, executeCmd
import subprocess
import logging 
import argparse
import configparser
import warnings
import paramiko
import re

def getLocalKey(cmd, path):
    """ Uses ssh-keygen command to generate id_rsa.pub on localhost """
    
    executeCmd(cmd)
    out = subprocess.Popen ("cat" + " " + path, shell=True, stdout=subprocess.PIPE)
    key = out.stdout.read().rstrip('\n')
    logging.debug ("******** Local key has been generated successfully : %s ********", key)
    return key

def getRemoteKey(cmd, path, ip, user, passwd):
    """ Uses ssh-keygen command over SSH to generate id_rsa.pub on remotehost """
    
    remote_key_generation_result = sshToOtherClient (ip, user, passwd, cmd)
    showKeyCmd = 'cat %s' %(path)
    remote_key = sshToOtherClient (ip, user, passwd, showKeyCmd)
    logging.debug ("******** Remote key for %s has been generated successfully : %s ********", ip, remote_key)
    return remote_key

def appendLocalKeyInRemote(key, authorized_key_path, ip, user, passwd):
    """ Adds localkey as an authorized key in remotehost over SSH """

    key_append_cmd = 'echo "%s" >> %s' %(key, authorized_key_path)
    sshToOtherClient (ip, user, passwd, key_append_cmd)
    logging.debug ("******** Local key has been added into authorized_keys in %s ********", ip)

def appendRemoteKeyInLocal(key, authorized_key_path, ip):
    """ Adds remote key as an authorized key into localhost """ 

    key_append_cmd = 'echo "%s" >> %s' %(key, authorized_key_path)
    executeCmd(key_append_cmd)
    logging.debug ("******** Remote key for %s has been added into authorized_keys in LocalHost ********", ip)

def validateHostCodes(machinelist, codes):
    """ Validates the host codes against a supported list """

    codelist = list(codes)
    for i in machinelist:
        if i[0].lower() not in codelist:
            logging.info ("******** Inventory generation failed, please check host code '%s' ********", i[0])
            exit()

def generateInventory(config, boxlist, path, codes):
    """ Generates inventory.cfg file using configparser module  """

    c = 1
    for i in boxlist:
        hostgroupname = codes[i[0]]
        user = "\"{{ lookup('env','%s') }}\"" %(i[2])
        passwd = "\"{{ lookup('env','%s') }}\"" %(i[3])

        if c == 1:
            hostaliasname = '%s0%s ansible_ssh_host' %(i[0], c)
            config[hostgroupname] = {hostaliasname:i[1]}
            f = open(path, 'w')
            config.write(f)
            f.close()
            c = c + 1

            varsgroupname = '%s:vars' %(hostgroupname)
            config[varsgroupname] = {'ansible_ssh_user': user}
            config[varsgroupname]['ansible_ssh_pass'] = passwd
            config[varsgroupname]['ansible_become_pass'] = passwd
            config[varsgroupname]['ansible_ssh_extra_args'] = "'-o StrictHostKeyChecking=no'"
            f = open(path, 'w')
            config.write(f)
            f.close()

        elif c > 1:
            hostaliasname = '%s0%s ansible_ssh_host' %(i[0], c)
            config[hostgroupname][hostaliasname] = i[1]
            f = open(path, 'w')
            config.write(f)
            f.close()
            c = c + 1
    
def replace(file, pattern, subst):
    """ Replace extra spaces around assignment operator in inventory """

    file_handle = open(file, 'rb')
    file_string = file_handle.read()
    file_handle.close()

    file_string = (re.sub(pattern, subst, file_string))

    file_handle = open(file, 'wb')
    file_handle.write(file_string)
    file_handle.close()

def main():
    
    # Suppress stdout from the python script execution
    f = open(os.devnull, 'w')
    sys.stdout = f

    # Suppress warnings from deprecated functions (configparser compatibility for python 3)
    warnings.simplefilter("ignore", category=DeprecationWarning)
    warnings.filterwarnings("ignore")

    # Specify, parse & assign positional (compulsory) & optional arguments for the script
    parser = argparse.ArgumentParser(description='Take the hostfile and logging level')
    parser.add_argument("hostfile", help="Provide a hostfile in ip,username,password format")
    parser.add_argument("--loglevel", help="Provide a log level amongst INFO,DEBUG. Default is INFO")
    args = parser.parse_args()

    Hosts = args.hostfile
   
    # Specify SSH details 
    key_rsa_path = '~/.ssh/id_rsa.pub'
    key_append_path = '~/.ssh/authorized_keys'
    key_gen_cmd = 'echo -e  "y\n"|ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'

    # Create the configparser object
    config = configparser.ConfigParser()
    
    # Specify path for inventory
    ansible_path = os.path.dirname(os.path.dirname(os.path.realpath(sys.argv[0])))
    ansible_cfg_path = ansible_path + 'ansible.cfg'
    default_inventory_path = ansible_path + '/inventory/'
    try:
        config.read_file(open(ansible_cfg_path))
        inventory_path = ansible_path + config.get('defaults', 'inventory')
    except:
        if os.path.isdir(default_inventory_path) != True:
           os.makedirs(default_inventory_path)
	inventory_path = default_inventory_path + 'hosts'
    
    # Define logging levels for script execution
    logfile = '%s/host-status.log' %(default_inventory_path)
    
    if args.loglevel and args.loglevel.upper() == "DEBUG":
	logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',\
		filename=logfile,filemode='a',level=10)
    else:
	logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',\
		filename=logfile,filemode='a',level=20)

    # Initiate log file
    clearLogCmd = '> %s' %(logfile)
    executeCmd(clearLogCmd)

    # Initialize dictionary holding supported host codes
    SupportedHostCodes = {'localhost': None, 'mayamaster': 'openebs-mayamasters', 'mayahost': 'openebs-mayahosts',\
            'kubemaster': 'kubernetes-kubemasters', 'kubeminion': 'kubernetes-kubeminions'}
      
    # Create list of tuples containing individual machine info & initialize localhost password
    HostList = []; local_password = None
    with open(Hosts, "rb") as fp:
        for i in fp.readlines():
            tmp = i.split(",")
            if "#" not in tmp[0]:
                if tmp[0] == "localhost":
                    local_password = tmp[3].rstrip('\n')
                else:
                    try:
                        HostList.append((tmp[0],tmp[1],tmp[2],tmp[3].rstrip('\n')))
                    except:pass

    # Validate the host code read from machines.in
    validateHostCodes(HostList, SupportedHostCodes)
    

    # Generate SSH key on localhost
    LocalKey = getLocalKey(key_gen_cmd, key_rsa_path )

    # Setup passwordless SSH with each of the specified machines
    for i in HostList:
        box_ip = i[1]
        user = i[2]
        pwd = i[3]

        out = subprocess.Popen("echo $" + user, shell=True, stdout=subprocess.PIPE)
        box_user = out.stdout.read().rstrip('\n')

        out = subprocess.Popen("echo $" + pwd, shell=True, stdout=subprocess.PIPE)
        box_pwd = out.stdout.read().rstrip('\n')

        try:
            RemoteKey = getRemoteKey(key_gen_cmd, key_rsa_path, box_ip, box_user, box_pwd)

            appendLocalKeyInRemote(LocalKey, key_append_path, box_ip, box_user, box_pwd)

            appendRemoteKeyInLocal(RemoteKey, key_append_path, box_ip)

            logging.info ("******** Passwordless SSH has been setup b/w localhost & %s ******** ", box_ip)
        except:
            logging.info ("******** Passwordless SSH setup failed b/w localhost & %s," \
                    "please verify host connectivity********", box_ip)

    # Generate Ansible hosts file from 'machines.in'
    codes = list(SupportedHostCodes)
    for i in codes:
        codeSubList = []
        for j in HostList:
            if i in j:
                codeSubList.append(j)
        generateInventory(config, codeSubList, inventory_path, SupportedHostCodes)
    
    logging.info ("******** Inventory config generated successfully ********") 	
    
    # Insert localhost line into beginning of inventory file
    if local_password:
        lpasswd = "\"{{ lookup('env','%s') }}\"" %(local_password)
        localhostString = "localhost ansible_connection=local ansible_become_pass=%s\n\n" %(lpasswd) 
        with open(inventory_path, 'rb') as f:
            with open('hosts.tmp', 'wb') as f2:
                f2.write(localhostString)
                f2.write(f.read())
        os.rename('hosts.tmp', inventory_path)


    # Sanitize the Ansible inventory file
    replace(inventory_path, " = ", "=" )

if __name__=="__main__":
    main()


