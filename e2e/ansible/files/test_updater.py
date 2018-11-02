import unittest
import unittest.mock as mock
import json
import updater
import testrail


class TestUpdater(unittest.TestCase):

    def setUp(self):
        self.some_args = {'testrail_username': 'AzureDiamond',
                          'testrail_password': 'hunter2',
                          'engine_type': 'eng_t',
                          'suite_id': 'sui_id',
                          'case_id': 'cas_id',
                          'status_id': 'sta_id'}
        self.mock_client = mock.MagicMock()
        self.mock_send_post = mock.MagicMock()
        self.mock_client.send_post = self.mock_send_post

    def test_client(self):
        args = {'testrail_username': 'AzureDiamond',
                'testrail_password': 'hunter2'}
        client = updater.get_testrail_client(args)
        self.assertEqual(client.user, 'AzureDiamond')
        self.assertEqual(client.password, 'hunter2')

    def test_json(self):
        dummy_json = {'a': 1, 'b': ['hello']}
        mock_open = mock.mock_open(read_data=json.dumps(dummy_json))
        path = 'some/path'
        with mock.patch('updater.open', mock_open):
            result, err = updater.get_json_file_data(path)
        self.assertIsNone(err)
        self.assertEqual(result, dummy_json)
        self.assertIn(path, mock_open.call_args[0])

    def test_json_file_not_found(self):
        mock_open = mock.Mock(side_effect=FileNotFoundError)
        path = 'some/other/path'
        with mock.patch('updater.open', mock_open):
            result, err = updater.get_json_file_data(path)
        self.assertIsNotNone(err)
        self.assertIsInstance(err, FileNotFoundError)
        self.assertIsNone(result)

    def test_json_ill_formed_json(self):
        mock_open = mock.mock_open(read_data='this is not {proper] json')
        path = 'some/path'
        with mock.patch('updater.open', mock_open):
            result, err = updater.get_json_file_data(path)
        self.assertIsNotNone(err)
        self.assertIsInstance(err, ValueError)
        self.assertIsNone(result)

    @mock.patch('updater.get_testrail_client')
    @mock.patch('updater.get_json_file_data')
    def test_update(self, mock_get_json, mock_get_client):
        return_json = {'eng_t': {'sui_id': 'sui_run_id'}}
        mock_get_json.return_value = (return_json, None)
        mock_get_client.return_value = self.mock_client
        result = updater.update_testrail_with_status(self.some_args)
        mock_get_client.assert_called_with(self.some_args)
        mock_get_json.assert_called()
        self.assertNotIsInstance(result, Exception)
        self.mock_send_post.assert_called()
        post_uri = self.mock_send_post.call_args[0][0]
        post_data = self.mock_send_post.call_args[0][1]
        self.assertIn('sui_run_id', post_uri)
        self.assertIn('cas_id', post_uri)
        self.assertEqual(post_data['status_id'], 'sta_id')

    @mock.patch('updater.get_testrail_client')
    @mock.patch('updater.get_json_file_data')
    def test_update_bad_json(self, mock_get_json, mock_get_client):
        mock_get_json.return_value = (None, FileNotFoundError())
        mock_get_client.return_value = self.mock_client
        result = updater.update_testrail_with_status(self.some_args)
        self.mock_send_post.assert_not_called()
        self.assertIsInstance(result, FileNotFoundError)

    @mock.patch('updater.get_testrail_client')
    @mock.patch('updater.get_json_file_data')
    def test_update_api_error(self, mock_get_json, mock_get_client):
        return_json = {'eng_t': {'sui_id': 'sui_run_id'}}
        mock_get_json.return_value = (return_json, None)
        mock_get_client.return_value = self.mock_client
        self.mock_send_post.side_effect = testrail.APIError
        result = updater.update_testrail_with_status(self.some_args)
        self.assertIsInstance(result, testrail.APIError)

    @mock.patch('updater.get_testrail_client')
    @mock.patch('updater.get_json_file_data')
    def test_update_key_error(self, mock_get_json, mock_get_client):
        return_json = {'wrong_key': {'sui_id': 'sui_run_id'}}
        mock_get_json.return_value = (return_json, None)
        mock_get_client.return_value = self.mock_client
        result = updater.update_testrail_with_status(self.some_args)
        self.assertIsInstance(result, KeyError)
        self.mock_send_post.assert_not_called()
