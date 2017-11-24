'''
Class for managing Inventory generation
'''


class Inventory(object):

    def __init__(self):
        pass

    def generateInventory(self, config, boxlist, path, codes, pwdless):
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

                        eargs = "'-o StrictHostKeyChecking=no'"
                        config[varsgroupname]['ansible_ssh_extra_args'] = eargs

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

                except KeyError:
                    err_text = "Unable to construct hosts file,received error:"
                    return False, err_text
        return True, "Success"
