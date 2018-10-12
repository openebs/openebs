import argparse
import json
import os
import testrail


def get_testrail_client(args):
    testrail_username = args['testrail_username']
    testrail_password = args['testrail_password']
    client = testrail.APIClient('https://cloudbyte.testrail.com')
    client.user = testrail_username
    client.password = testrail_password
    return client


def get_json_file_data(path):
    try:
        json_file = open(path, 'r')
        data = json.load(json_file)
        json_file.close()
    except EnvironmentError as e:
        # print("File operation failed, Error: %s" % e)
        return None, e
    except ValueError as e:
        # print("JSON operation failed, Error: %s" % e)
        return None, e
    return data, None


def update_testrail_with_status(args):
    testrail_client = get_testrail_client(args)
    suites, err = get_json_file_data('{}/mapping.json'.format(os.path.expanduser('~')))
    if err != None:
        print('TestRail Update Failed.')
        return err
    try:
        suite_run_id = suites[args['engine_type']][args['suite_id']]
        r = testrail_client.send_post('add_result_for_case/{}/{}'.format(suite_run_id, args['case_id']),
                                      {'status_id': args['status_id']}
                                      )
        # print('Successfully updated case_id - %s' % args['case_id'])
        print('TestRail Updated.')
        return None
    except testrail.APIError as e:
        # print('failed due to api error, error - %s' % e)
        print('TestRail Update Failed.')
        return e
    except KeyError as e:
        # print('Key not found, error - %s' % e)
        print('TestRail Update Failed.')
        return e


def main():
    parser = argparse.ArgumentParser(description='cli to get required details')
    parser.add_argument('-tuser', '--testrail-username', help='username for testrail', required=True)
    parser.add_argument('-tpass', '--testrail-password', help='password for testrail', required=True)
    parser.add_argument('-sid', '--suite-id', help='suite id to update test case in testrail', required=True)
    parser.add_argument('-cid', '--case-id', help='case id for which result is to be updated', required=True)
    parser.add_argument('-stid', '--status-id', help='status id i.e result test passed or failed', required=True)
    parser.add_argument('-et', '--engine-type', help='storage engine type', required=True)
    args = vars(parser.parse_args())
    update_testrail_with_status(args)


if __name__ == "__main__":
    main()
