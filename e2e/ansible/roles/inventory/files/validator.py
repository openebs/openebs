import socket
import os
'''
Class for validation methods
'''


class Validator(object):
    def __init__(self):
        pass

    def validateIP(self, ip):
        try:
            socket.inet_aton(ip)
            return True
        except socket.error:
            return False

    def validateInput(self, i_line, codes):
        """ Validates the host codes against a supported list """
        msg = ""
        codelist = list(codes)
        if len(i_line) != 4:
            msg = "Invalid row length in line: %s" % (','.join(i_line))
            return False, msg
        if self.validateIP(i_line[1]) is False:
            msg = "IP is invalid in line: %s" % (','.join(i_line))
            return False, msg
        for j in i_line[2], i_line[3].rstrip('\n'):
            if j not in os.environ:
                msg = "Variable not in env, from line: %s" % (','.join(i_line))
                return False, msg
        if i_line[0].lower() not in codelist:
            msg = "Invalid host code in line: %s" % (','.join(i_line))
            return (False, msg)
        return True, msg
