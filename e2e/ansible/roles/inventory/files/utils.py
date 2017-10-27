import subprocess
import paramiko
import os
import getpass
import sys

def executeCmd(command):
    link = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, close_fds=True)
    ldata = link.stdout.readlines()
    output, errors = link.communicate()
    rco = link.returncode
    if rco != 0:
        return "FAILED", str(errors)
    return "PASSED", ""; 

ssh = paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())

def sshToOtherClient(ip, usrname, pwd, cmd):
    ssh.connect(ip, username=usrname, password=pwd)
    stdin, stdout, stderr = ssh.exec_command(cmd)
    output = stdout.read()
    error = stderr.read()
    ssh.close()
    if not error and output:
        return output
    else:
        return error

