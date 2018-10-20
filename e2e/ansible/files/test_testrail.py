#
# TestRail API binding for Python 3.x (API v2, available since
# TestRail 3.0)
#
# Learn more:
#
# http://docs.gurock.com/testrail-api2/start
# http://docs.gurock.com/testrail-api2/accessing
#
# Copyright Gurock Software GmbH. See license.md for details.
#

import unittest

from unittest.mock import patch
from e2e.ansible.files.testrail import APIClient



class TestcaseTestrail(unittest.TestCase):
    @patch('testrail.urllib.request.urlopen')  # Mock 'requests' module 'get' method.
    def test_send_request(self, mock_util):
        """Mocking using a decorator"""
        mock_util.return_value.status_code = 200 # Mock status code of response.
        response = APIClient.send_get(self, 'GET', "sampleuri.com")
        _
        # Assert that the request-response cycle completed successfully.
        self.assertEqual(response.status_code, 200)


if __name__ == "__main__":
    unittest.main()

