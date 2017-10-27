#Make coding more python3-ish
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


from ansible.plugins.callback.default import CallbackModule as CallbackModule_default
from ansible import constants as C

#Implementation of Custom Class that inherits the 'default' stdout_callback plugin 
#and overrides the v2_runner_retry api for displaying the 'FAILED - RETRYING' only 
#during verbose mode.
class CallbackModule(CallbackModule_default):


    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'openebs'
    CALLBACK_NEEDS_WHITELIST = False

    def v2_runner_retry(self, result):
        task_name = result.task_name or result._task
        msg = "FAILED - RETRYING: %s (%d retries left)." % (task_name, result._result['retries'] - result._result['attempts'])
        if (self._display.verbosity > 2 or '_ansible_verbose_always' in result._result) and not '_ansible_verbose_override' in result._result:
           msg+= "Result was: %s" % self._dump_results(result._result)
        self._display.v('%s' %(msg))

    def v2_runner_on_skipped(self, result):

        if C.DISPLAY_SKIPPED_HOSTS:
            if (self._display.verbosity > 0 or '_ansible_verbose_always' in result._result) and not '_ansible_verbose_override' in result._result:
                msg = "skipping: [%s] => %s" % (result._host.get_name(), self._dump_results(result._result))
                self._display.display(msg, color=C.COLOR_SKIP)
            else: 
                self._display.display("skipping task..", color=C.COLOR_SKIP)

    def v2_runner_item_on_skipped(self, result):
        
        if C.DISPLAY_SKIPPED_HOSTS:
            if (self._display.verbosity > 0 or '_ansible_verbose_always' in result._result) and not '_ansible_verbose_override' in result._result:
                msg = "skipping: [%s] => (item=%s) => %s" % (result._host.get_name(), self._get_item(result._result), self._dump_results(result._result))
                self._display.display(msg, color=C.COLOR_SKIP)






