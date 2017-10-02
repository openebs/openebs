# Make coding more python3-ish
from __future__ import (absolute_import, division, print_function)
__metaclass__ = type


from ansible.plugins.callback.default import (
    CallbackModule as CallbackModule_default
)
from ansible import constants as C

"""Implementation of Custom Class that inherits the 'default' stdout_callback
plugin and overrides the v2_runner_retry api for displaying the 'FAILED -
RETRYING' only during verbose mode."""


class CallbackModule(CallbackModule_default):

    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'openebs'
    CALLBACK_NEEDS_WHITELIST = False

    def v2_runner_retry(self, result):
        task_name = result.task_name or result._task
        final_result = result._result['retries'] - result._result['attempts']
        msg = "FAILED - RETRYING: %s (%d retries left)." % (task_name,
                                                            final_result)
        display_verbosity = self._display.verbosity
        required_result = '_ansible_verbose_always'
        if (display_verbosity > 2 or required_result in result._result):
            if required_result not in result._result:
                msg += "Result was: %s" % self._dump_results(result._result)
        self._display.v('%s' % (msg))

    def v2_runner_on_skipped(self, result):
        my_result = result._result
        required_result = '_ansible_verbose_always'

        if C.DISPLAY_SKIPPED_HOSTS:
            if (self._display.verbosity > 0 or required_result in my_result):
                if required_result not in my_result:
                    dumped_results = self._dump_results(my_result)
                    msg = "skipping: [%s] => %s" % (result._host.get_name(),
                                                    dumped_results)
                    self._display.display(msg, color=C.COLOR_SKIP)

            else:
                self._display.display("skipping task..", color=C.COLOR_SKIP)

    def v2_runner_item_on_skipped(self, result):
        my_result = result._result
        required_result = '_ansible_verbose_always'

        if C.DISPLAY_SKIPPED_HOSTS:
            if (self._display.verbosity > 0 or required_result in my_result):
                if required_result not in my_result:
                    required_item = self._get_item(my_result)
                    dumped_result = self._dump_results(my_result)
                    result_host = result._host.get_name()
                    msg = "skipping: [%s] => (item=%s) => %s" % (result_host,
                                                                 required_item,
                                                                 dumped_result)
                self._display.display(msg, color=C.COLOR_SKIP)
