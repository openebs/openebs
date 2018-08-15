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

def create_test_plan(client, args, storage_engine_type, project_id):
    plan_name = "BUILD_"+ storage_engine_type + "_" + args['build_number'] + "_" + str(datetime.now())[:10]
    description = "A description"
    plan = client.send_post('add_plan/'+str(project_id), {'name': plan_name, 'description': description})
    if plan['id'] is None:
        print("Plan creation failed")
        exit(-1)
    return plan['id']

def add_suites(plan_id, suite_id, client, suite_info, project_id):
    description = ""
    if suite_info is not None and 'Exclude' in suite_info and suite_info['Exclude'] is not None:
        ids, paths = [], []
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
    client, yaml_info  = get_client(args), parse_yaml(get_file_data("../playbooks/test_suites.yml"))
    map_src_id, run_id, project_id, cstor_plan_resources, jiva_plan_resources = {'cstor':{},'jiva':{}}, 0, yaml_info['TestRailProjectID'], [], []

    yaml_header = [{
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
        }
    ]
    yaml_footer = [{
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
                        "msg": "TestRail Results : <https://cloudbyte.testrail.com/index.php?/runs/view/"+str(run_id)+"|"+str(run_id)+">",
                        "token": "{{ lookup('env','SLACK_TOKEN') }}"
                    }
                },
                {
                    "when": "slack_notify | bool and lookup('env','SLACK_TOKEN')",
                    "slack": {
                        "msg": "{{ ansible_date_time.time }} OPENEBS TESTSUITE: ENDED",
                        "token": "{{ lookup('env','SLACK_TOKEN') }}"
                    }
                }
            ],
            "hosts": "localhost"
        },
    ]
 
    if yaml_info['CstorTestSuite'] is not None:
        cstor_plan_resources+=yaml_info['CstorTestSuite']
    if yaml_info['JivaTestSuite'] is not None:
        jiva_plan_resources+=yaml_info['JivaTestSuite']
    if yaml_info['CommonTestSuite'] is not None:
        cstor_plan_resources+=yaml_info['CommonTestSuite']
        jiva_plan_resources+=yaml_info['CommonTestSuite']
    
    print("Creating test plans")

    if len(cstor_plan_resources)>0:
        map_src_id["cstor_plan_run_id"], paths, cstor_test_yaml = create_test_plan(client, args, "CSTOR", project_id), [], []
        for suites in cstor_plan_resources:
            for suite_name, suite_info in suites.items():
                suite_run_id, tpaths = add_suites(map_src_id["cstor_plan_run_id"], suite_name, client, suite_info, project_id)
                map_src_id['cstor'][suite_name]=suite_run_id
                paths+=tpaths

        cstor_test_yaml += yaml_header
        
        for path in paths:
            cstor_test_yaml.append({'include': path})

        cstor_test_yaml += yaml_footer
        
        _, err = write_file("../cstor-run-tests.yml", yaml.dump(cstor_test_yaml, default_flow_style=False))
        if err == -1:
            exit(err)

        print("Cstor plan created")

    if len(jiva_plan_resources)>0:
        map_src_id['jiva_plan_run_id'], paths, jiva_test_yaml = create_test_plan(client, args, "JIVA", project_id), [], []
        
        for suites in jiva_plan_resources:
            for suite_name, suite_info in suites.items():
                suite_run_id, tpaths = add_suites(map_src_id["jiva_plan_run_id"], suite_name, client, suite_info, project_id)
                map_src_id['jiva'][suite_name]=suite_run_id
                paths += tpaths
        
        jiva_test_yaml += yaml_header
        
        for path in paths:
            jiva_test_yaml.append({'include': path})

        jiva_test_yaml += yaml_footer
        
        _, err = write_file("../jiva-run-tests.yml", yaml.dump(jiva_test_yaml, default_flow_style=False))
        if err == -1:
            exit(err)

        print("Jiva plan created")
    
    _, err = write_file(os.path.expanduser('~') + "/mapping.json", json.dumps(map_src_id))
    if err == -1:
        exit(err)

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
