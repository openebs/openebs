import subprocess
import paramiko
import re


def executeCmd(command):
    link = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, close_fds=True)
    output, errors = link.communicate()
    rco = link.returncode
    if rco != 0:
        return "FAILED", str(errors)
    return "PASSED", ""


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


def replace(file, pattern, subst):
    """ Replace extra spaces around assignment operator in inventory """

    file_handle = open(file, 'rb')
    file_string = file_handle.read()
    file_handle.close()
    file_string = (re.sub(pattern, subst, file_string))
    file_handle = open(file, 'wb')
    file_handle.write(file_string)
    file_handle.close()
