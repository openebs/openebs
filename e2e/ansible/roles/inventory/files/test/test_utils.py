"""Tests for utils."""
from __future__ import absolute_import

import unittest
import sys
import os
from utils import replace  # flake8: noqa

sys.path.insert(1, os.path.join(sys.path[0], '..'))


class utilsTest(unittest.TestCase):
    def setUp(self):
        with open('./test.txt', 'w') as outfile:
            outfile.write('foo = bar')

    def test_010_replace(self):
        replace('./test.txt', ' = ', '=')
        with open('./test.txt', 'r') as infile:
            txt = infile.read()
        self.assertEqual(txt, 'foo=bar')

    def tearDown(self):
        os.remove('./test.txt')


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(utilsTest)
    unittest.TextTestRunner(verbosity=2).run(suite)
