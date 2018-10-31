"""Tests for utils."""
from __future__ import absolute_import

import unittest
import sys
import os
from validator import Validator  # flake8: noqa

sys.path.insert(1, os.path.join(sys.path[0], '..'))


class validatorTest(unittest.TestCase):
    def setUp(self):
        os.environ['USER_NAME'] = 'test'
        os.environ['USER_PASSWORD'] = 'test'

    def test_010_validateip(self):
        v = Validator()
        self.assertEqual(v.validateIP("127.0.0.1"), True)
        self.assertEqual(v.validateIP("foo"), False)

    def test_020_validate_input(self):
        v = Validator()
        good_line = ['localhost', '127.0.0.1', 'USER_NAME', 'USER_PASSWORD']
        bad_line = ['localhost', '127.0.0.1', 'USER_NAME1', 'USER_PASSWORD1']
        ret, msg = v.validateInput(good_line, ['localhost'])
        self.assertEqual(ret, True)
        ret, msg = v.validateInput(good_line, ['local'])
        self.assertEqual(ret, False)
        ret, msg = v.validateInput(bad_line, ['localhost'])
        self.assertEqual(ret, False)


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(validatorTest)
    unittest.TextTestRunner(verbosity=2).run(suite)
