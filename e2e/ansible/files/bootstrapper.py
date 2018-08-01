import testrail
import argparse
import yaml
import os
import json
from pprint import pprint
from datetime import datetime


def get_client(args):
    client = testrail.APIClient("https://cloudbyte.testrail.com")
    client.user, client.password = args['testrail_username'], args["testrail_password"]
    return client


def write_file(path, content):
    try:
        file = open(path, "w+")
        file.write(content)
        file.close()
    except EnvironmentError as e:
        print("File operation failed\nError: %s" % e)
        return "", -1
    return path, 0


def create_test_plan(client, args, project_id):
    plan_name = "BUILD_" + args['build_number'] + "_" + str(datetime.now())[:10]
    description = "A description"
    plan = client.send_post('add_plan/'+str(project_id), {'name': plan_name, 'description': description})
    if plan['id'] is None:
        print("Plan creation failed")
        exit(-1)
    return plan['id']


def add_suites(plan_id, suite_id, client, suite_info, project_id):
    description = ""
    if suite_info is not None and 'Exclude' in suite_info:
        ids = []
        paths = []
        cases = client.send_get('get_cases/'+str(project_id)+'&suite_id=' + str(suite_id))
        for case in cases:
            if case['id'] in suite_info['Exclude']:
                continue
            else:
                paths.append(case['refs'])
                ids.append(case['id'])
        suite = client.send_post('add_plan_entry/' + str(plan_id),
                                 {'suite_id': suite_id, 'description': description, 'include_all': False,
                                  'case_ids': ids})
        if suite['id'] is None:
            print("Adding suite failed")
            exit(-1)
        return suite['runs'][0]['id'], paths
    else:
        cases = client.send_get('get_cases/'+str(project_id)+'&suite_id=' + str(suite_id))
        paths = []
        for case in cases:
            paths.append(case['refs'])
        suite = client.send_post('add_plan_entry/' + str(plan_id), {'suite_id': suite_id, 'description': description})
        if suite['id'] is None:
            print("Adding suite failed")
            exit(-1)
        return suite['runs'][0]['id'], paths


def get_file_data(path):
    try:
        file = open(path, 'r')
        data = file.read()
        file.close()
    except EnvironmentError as e:
        print("File operation failed, Error: %s" % e)
        exit(-1)
    return data


def create_plan_resources(args):
    client = get_client(args)
    map_src_id = {"platforms": {}}
    paths = []
    run_id = 0
    yaml_info = parse_yaml(get_file_data("../playbooks/test_suites.yml"))
    project_id= yaml_info['TestRailProjectID']
    for platforms in yaml_info['Platform']:
        for platform_name, platform_info in platforms.items():
            plan_run_id = create_test_plan(client, args, project_id)
            map_src_id["plan_run_id"] = plan_run_id
            map_src_id["platforms"][platform_name] = {'suites': {}}
            for suites in platform_info['Test Suite']:
                for suite_name, suite_info in suites.items():
                    suite_run_id, tpaths = add_suites(plan_run_id, suite_name, client, suite_info, project_id)
                    map_src_id["platforms"][platform_name]["suites"][suite_name] = suite_run_id
                    paths = paths + tpaths
                    run_id = suite_run_id
    _, err = write_file(os.path.expanduser('~') + "/mapping.json", json.dumps(map_src_id))
    if err == -1:
        exit(err)

    test_yaml = [{
            "tasks": [
                {
                    "when": "slack_notify | bool and lookup('env','SLACK_TOKEN')",
                    "slack": {
                        "msg": "{{ ansible_date_time.time }} OPENEBS TESTSUITE: STARTED",
                        "token": "{{ lookup('env','SLACK_TOKEN') }}"
                    }
                }
            ],
            "hosts": "localhost"
        },
        {
            "include": "pre-check.yml"
        }]

    for path in paths:
        test_yaml.append({'include': path})

    test_yaml = test_yaml + [{
        "include": "pre-check.yml"
    },
        {
            "hosts": "localhost",
            "roles": [
                {
                    "role": "logging",
                    "when": "logging | bool and deployment_mode == \"hyperconverged\""
                }
            ]
        },
        {
            "tasks": [
                {
                    "when": "slack_notify | bool and lookup('env','SLACK_TOKEN')",
                    "slack": {
                        "msg": "{{ ansible_date_time.time }} OPENEBS TESTSUITE: ENDED",
                        "token": "{{ lookup('env','SLACK_TOKEN') }}"
                    }
                },
                {
                    "when": "slack_notify | bool and lookup('env','SLACK_TOKEN')",
                    "slack": {
                        "msg": "Results Updated:https://cloudbyte.testrail.com/index.php?/runs/view/"+str(run_id),
                        "token": "{{ lookup('env','SLACK_TOKEN') }}"
                    }
                }
            ],
            "hosts": "localhost"
        },
    ]
    _, err = write_file("../run-tests.yml", yaml.dump(test_yaml, default_flow_style=False))
    if err == -1:
        exit(-1)


def parse_yaml(content):
    try:
        r = yaml.load(content)
    except yaml.YAMLError as e:
        print("YAML operation failed\nError: %s" % e)
        exit(-1)
    return r


def main():
    parser = argparse.ArgumentParser(description="Command Line tool for creating plan")
    parser.add_argument('-tuser', '--testrail-username', help='username for testrail', required=True)
    parser.add_argument('-tpass', '--testrail-password',
                        help='password for testrail', required=True)
    parser.add_argument('-bn', '--build-number', help='jenkins build number', required=True)
    args = vars(parser.parse_args())
    create_plan_resources(args)
    exit(0)


if __name__ == "__main__":
    main()
