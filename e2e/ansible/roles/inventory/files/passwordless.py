#######################################################################
# This utils file can be used to setup passwordless SSH between the
# machine on which it is executed and other target hosts. The method
# to invoke the function and arguments required are expalined below :
#
# setupSSH(key_rsa_path, key_append_path, key_gen_cmd, HostList), where
#
# key_rsa_path = Location of the rsa public key file
# key_append_path = Location of the authorized_keys file on localhost
# key_gen_cmd = Key generation command to be used on local/remote hosts
# HostList = A list which contains tuples of details for each host
#
# The sample HostList is constructed as shown. Note that the USERNAME
# and PASSWORD here are environment variables from the .profile of the
# local user.
#
# [('mayamaster',20.10.49.11,'USERNAME','PASSWORD'),
# ('mayahost',20.10.49.12,'USERNAME','PASSWORD')]
#######################################################################

from utils import sshToOtherClient, executeCmd
import logging
import paramiko
import subprocess
import socket


def getLocalKey(cmd, path):
    """ Uses ssh-keygen command to generate id_rsa.pub on localhost """

    executeCmd(cmd)
    out = subprocess.Popen("cat" + " " + path, shell=True,
                           stdout=subprocess.PIPE)
    key = out.stdout.read().rstrip('\n')
    logging.debug("Local key has been generated successfully : %s ", key)
    return key


def getRemoteKey(cmd, path, ip, user, passwd):
    """Uses ssh-keygen command over SSH to generate id_rsa.pub on remotehost"""

    showKeyCmd = 'cat %s' % (path)
    remote_key = sshToOtherClient(ip, user, passwd, showKeyCmd)
    logging.debug("Remote key for %s has been generated successfully : %s",
                  ip, remote_key)
    return remote_key


def appendLocalKeyInRemote(key, authorized_key_path, ip, user, passwd):
    """ Adds localkey as an authorized key in remotehost over SSH """

    key_append_cmd = 'echo "%s" >> %s' % (key, authorized_key_path)
    sshToOtherClient(ip, user, passwd, key_append_cmd)
    logging.debug("Local key has been added into authorized_keys in %s", ip)


def appendRemoteKeyInLocal(key, authorized_key_path, ip):
    """ Adds remote key as an authorized key into localhost """

    key_append_cmd = 'echo "%s" >> %s' % (key, authorized_key_path)
    executeCmd(key_append_cmd)
    debug_text = """Remote key for %s has been added into authorized_keys in
    LocalHost"""
    logging.debug(debug_text, ip)


def setupSSH(key_rsa_path, key_append_path, key_gen_cmd, HostList):
    """Setups up passwordless SSH between the localhost
    and other target hosts"""
    # Generate SSH key on localhost
    LocalKey = getLocalKey(key_gen_cmd, key_rsa_path)

    # Setup passwordless SSH with each of the specified machines
    for i in HostList:
        if i[0] != 'localhost':

            box_ip = i[1]
            user = i[2]
            pwd = i[3]

            out = subprocess.Popen("echo $" + user, shell=True,
                                   stdout=subprocess.PIPE)
            box_user = out.stdout.read().rstrip('\n')
            out = subprocess.Popen("echo $" + pwd, shell=True,
                                   stdout=subprocess.PIPE)
            box_pwd = out.stdout.read().rstrip('\n')
            try:

                RemoteKey = getRemoteKey(key_gen_cmd, key_rsa_path, box_ip,
                                         box_user, box_pwd)
                appendLocalKeyInRemote(LocalKey, key_append_path, box_ip,
                                       box_user, box_pwd)
                appendRemoteKeyInLocal(RemoteKey, key_append_path, box_ip)
                logging.info("Passwordless SSH has been setup b/w \
                localhost & %s", box_ip)

            except (paramiko.SSHException, paramiko.BadHostKeyException,
                    paramiko.AuthenticationException, socket.error) as e:
                logging.info("Passwordless SSH setup failed b/w localhost & %s \
                with %s, please verify host connectivity", box_ip, e)
