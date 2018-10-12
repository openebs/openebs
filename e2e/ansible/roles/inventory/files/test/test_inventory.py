"""Tests for utils."""
from __future__ import absolute_import

import unittest
import sys
import os
import configparser
from inventory import Inventory  # flake8: noqa

sys.path.insert(1, os.path.join(sys.path[0], '..'))


class inventoryTest(unittest.TestCase):

    def test_010_validate_inventory(self):
        i = Inventory()
        config = configparser.ConfigParser()
        config.read_file(open('./ansible.cfg'))
        box_list = [['local', '127.0.0.1', 'USER_NAME', 'USER_PASSWORD']]
        codes = {'local': 'test'}
        ret, msg = i.generateInventory(config, box_list, "./test.hosts", codes, "")
        self.assertEqual(ret, True)

    def tearDown(self):
        os.remove('./test.hosts')


if __name__ == '__main__':
    suite = unittest.TestLoader().loadTestsFromTestCase(inventoryTest)
    unittest.TextTestRunner(verbosity=2).run(suite)
