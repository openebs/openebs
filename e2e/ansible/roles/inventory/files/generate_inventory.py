#!/usr/bin/env python

#####################################################################
# This is a script used by the OpenEBS Ansible based CI to generate
# the inventory ('hosts') file which holds host groups and their
# respective variables. The script takes an input file 'machines.in',
# which contains host info as  mandatory argument while optionally
# taking arguments to set log-level and establish passwordless SSH
# between ansible test harness and target hosts.
#
# Upon successful execution, the script outputs an ansible 'hosts'
# file inside an inventory location, along with a status log which
# holds execution details.
#
# The script can be used in a standalone manner apart from its use
# in the 'pre-requisites' ansible role
#
# Usage Examples:
#
# python generate_inventory.py <path>/machines.in
#
# python generate_inventory.py <path>/machines.in --loglevel=Debug
#
# python generate_inventory.py <path>/machines.in --loglevel=Info \
#       --passwordless=True
#
######################################################################

import os
import sys
from utils import executeCmd
from passwordless import setupSSH
import logging
import argparse
import configparser
import warnings
import re
import socket


def IPvalidator(ip):
    try:
        socket.inet_aton(ip)
        return True
    except socket.error:
        return False


def validateInput(i_line, codes):
    """ Validates the host codes against a supported list """

    codelist = list(codes)
    if len(i_line) != 4:
        print "Invalid row length in line: %s" % (','.join(i_line))
        exit()
    if IPvalidator(i_line[1]) is False:
        print "IP is invalid in line: %s" % (','.join(i_line))
        exit()
    for j in i_line[2], i_line[3].rstrip('\n'):
        if j not in os.environ:
            print "Variable not in env, from line: %s" % (','.join(i_line))
            exit()
    if i_line[0].lower() not in codelist:
        print "Invalid host code in line: %s" % (','.join(i_line))
        exit()


def generateInventory(config, boxlist, path, codes, pwdless):
    """ Generates inventory.cfg file using configparser module  """

    c = 1
    for i in boxlist:
        if i[0] != 'localhost':
            hostgroupname = codes[i[0]]
            user = "\"{{ lookup('env','%s') }}\"" % (i[2])
            passwd = "\"{{ lookup('env','%s') }}\"" % (i[3])

            try:
                if c == 1:
                    hostaliasname = '%s0%s ansible_ssh_host' % (i[0], c)
                    config[hostgroupname] = {hostaliasname: i[1]}
                    f = open(path, 'w')
                    config.write(f)
                    f.close()
                    c = c + 1

                    varsgroupname = '%s:vars' % (hostgroupname)
                    config[varsgroupname] = {'ansible_ssh_user': user}

                    if not pwdless:
                        config[varsgroupname]['ansible_ssh_pass'] = passwd

                    config[varsgroupname]['ansible_become_pass'] = passwd

                    extraargs = "'-o StrictHostKeyChecking=no'"
                    config[varsgroupname]['ansible_ssh_extra_args'] = extraargs

                    f = open(path, 'w')
                    config.write(f)
                    f.close()

                elif c > 1:
                    hostaliasname = '%s0%s ansible_ssh_host' % (i[0], c)
                    config[hostgroupname][hostaliasname] = i[1]
                    f = open(path, 'w')
                    config.write(f)
                    f.close()
                    c = c + 1

            except KeyError as e:
                err_text = "Unable to construct hosts file, received error:"
                logging.info(err_text, e)


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

    """Suppress warnings from deprecated functions (configparser compatibility
    for python 3)"""
    warnings.simplefilter("ignore", category=DeprecationWarning)
    warnings.filterwarnings("ignore")

    """Specify, parse & assign positional (compulsory) & optional arguments for
    the script"""
    arg_parser_description = 'Take the hostfile, logging level and SSH details'
    parser = argparse.ArgumentParser(description=arg_parser_description)

    parser_help_text = "Provide a hostfile in ip,username,password format"
    parser.add_argument("hostfile", help=parser_help_text)

    parser.add_argument("--loglevel", help="Provide a log level. Supported values: (Info,Debug);\
            Default is Info")

    parser.add_argument("--passwordless", help="Setup passwordless SSH with hosts.\
             Supported values: (True,False); Default is False")

    args = parser.parse_args()

    Hosts = args.hostfile

    # Specify SSH details
    key_rsa_path = '~/.ssh/id_rsa.pub'
    key_append_path = '~/.ssh/authorized_keys'
    key_gen_cmd = 'echo -e  "y\n"|ssh-keygen -q -t rsa -N "" -f ~/.ssh/id_rsa'

    # Create the configparser object
    config = configparser.ConfigParser()

    # Specify path for inventory
    current_path = os.path.dirname(os.path.realpath(sys.argv[0]))

    if "ansible/roles/inventory/files" in current_path:
        parent_dirname = os.path.dirname(os.path.dirname(current_path))
        ansible_path = os.path.dirname(parent_dirname)
        ansible_cfg_path = ansible_path + 'ansible.cfg'
        default_inventory_path = ansible_path + '/inventory/'
        try:
            config.read_file(open(ansible_cfg_path))
            inventory_path = ansible_path + config.get('defaults', 'inventory')
        except IOError:
            if os.path.isdir(default_inventory_path) is not True:
                os.makedirs(default_inventory_path)
            inventory_path = default_inventory_path + 'hosts'
    else:
        os.makedirs('inventory')
        default_inventory_path = current_path + '/inventory/'
        inventory_path = default_inventory_path + 'hosts'

    # Define logging levels for script execution
    logfile = '%s/host-status.log' % (default_inventory_path)

    if args.loglevel and args.loglevel.upper() == "DEBUG":
        logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',
                            filename=logfile, filemode='a', level=10)
    else:
        logging.basicConfig(format='%(asctime)s %(levelname)s: %(message)s',
                            filename=logfile, filemode='a', level=20)

    # Initiate log file
    clearLogCmd = '> %s' % (logfile)
    executeCmd(clearLogCmd)

    # Initialize dictionary holding supported host codes
    SupportedHostCodes = {
            'localhost': None,
            'mayamaster': 'openebs-mayamasters',
            'mayahost': 'openebs-mayahosts',
            'kubemaster': 'kubernetes-kubemasters',
            'kubeminion': 'kubernetes-kubeminions'
            }

    """Create list of tuples containing individual machine info & initialize
    localhost password"""
    HostList = []
    local_password = None
    with open(Hosts, "rb") as fp:
        for i in fp.readlines():
            tmp = i.split(",")
            if tmp[0] != '\n' and "#" not in tmp[0]:

                validateInput(tmp, SupportedHostCodes)

                if tmp[0] == "localhost":
                    local_password = tmp[3].rstrip('\n')
                try:
                    HostList.append((tmp[0], tmp[1],
                                     tmp[2], tmp[3].rstrip('\n')))
                except IndexError as e:
                    info_text = "Unable to parse input, failed with error %s"
                    logging.info(info_text, e)
                    exit()

    if args.passwordless and args.passwordless.upper() == "TRUE":
        # Setup passwordless SSH between the localhost and target hosts
        setupSSH(key_rsa_path, key_append_path, key_gen_cmd, HostList)
        passwdless = True
    else:
        passwdless = False

    # Generate Ansible hosts file from 'machines.in'
    codes = list(SupportedHostCodes)
    for i in codes:
        codeSubList = []
        for j in HostList:
            if i in j:
                codeSubList.append(j)
        generateInventory(config, codeSubList,
                          inventory_path, SupportedHostCodes, passwdless)

    print "Inventory config generated successfully"
    logging.info("Inventory config generated successfully")

    # Insert localhost line into beginning of inventory file
    if local_password:
        lpasswd = "\"{{ lookup('env','%s') }}\"" % (local_password)
        localhostString = """localhost ansible_connection=local
        ansible_become_pass=%s\n\n""" % (lpasswd)

        with open(inventory_path, 'rb') as f:
            with open('hosts.tmp', 'wb') as f2:
                f2.write(localhostString)
                f2.write(f.read())
        os.rename('hosts.tmp', inventory_path)

    # Sanitize the Ansible inventory file
    replace(inventory_path, " = ", "=")


if __name__ == "__main__":
    main()
