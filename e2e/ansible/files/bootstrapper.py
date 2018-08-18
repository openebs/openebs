import testrail
import argparse
import yaml
import os
import json
from pprint import pprint
from datetime import datetime
import ruamel.yaml
import sys

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
    description = "Jenkins logs: http://104.197.185.168:8080/blue/organizations/jenkins/Jiva/detail/Jiva/"+str(args['build_number'])+"/pipeline/\nUsername: test\nPassword:"
    plan = client.send_post('add_plan/'+str(project_id), {'name': plan_name, 'description': description})
    if plan['id'] is None:
        print("Plan creation failed")
        exit(-1)
    return plan['id']

def add_suites(plan_id, suite_id, client, suite_info, project_id):
    description = ""
    if suite_info is not None and 'Exclude' in suite_info and suite_info['Exclude'] is not None:
        ids, case_resources = [], []
        cases = client.send_get('get_cases/'+str(project_id)+'&suite_id=' + str(suite_id))
        pprint(cases)
        for case in cases:
            if case['id'] in suite_info['Exclude']:
                continue
            else:
                case_resources.append({'path':case['refs'], 'suite_id':case['suite_id'], 'case_id':case['id']})
                ids.append(case['id'])
        suite = client.send_post('add_plan_entry/' + str(plan_id),
                                 {'suite_id': suite_id, 'description': description, 'include_all': False,
                                  'case_ids': ids})
        if suite['id'] is None:
            print("Adding suite failed")
            exit(-1)
        return suite['runs'][0]['id'], case_resources
    else:
        cases = client.send_get('get_cases/'+str(project_id)+'&suite_id=' + str(suite_id))
        case_resources=[]
        for case in cases:
            case_resources.append({'path':case['refs'], 'suite_id':case['suite_id'], 'case_id':case['id']})
            
        suite = client.send_post('add_plan_entry/' + str(plan_id), {'suite_id': suite_id, 'description': description})
        if suite['id'] is None:
            print("Adding suite failed")
            exit(-1)
        return suite['runs'][0]['id'], case_resources


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
    map_src_id, run_id, project_id, cstor_plan_resources, jiva_plan_resources = {'cStor':{},'jiva':{}}, 0, yaml_info['TestRailProjectID'], [], []

    ci_info = parse_yaml(get_file_data('../ci_config.yaml'))
    ci_yaml=[]
    for item in ci_info['include_before']:
        ci_yaml.append({'include': item})
 
    if 'CstorProductionTestSuite' in yaml_info and yaml_info['CstorProductionTestSuite'] is not None:
        cstor_plan_resources+=yaml_info['CstorProductionTestSuite']
    else:
        print('Key: CstorProductionTestSuite not provided. Moving on...')
    if 'CstorDevelopmentTestSuite' in yaml_info and yaml_info['CstorDevelopmentTestSuite'] is not None:
        cstor_plan_resources+=yaml_info['CstorDevelopmentTestSuite']
    else:
        print('Key: CstorDevelopmentTestSuite not provided. Moving on...')
    if 'JivaProductionTestSuite' in yaml_info and yaml_info['JivaProductionTestSuite'] is not None:
        jiva_plan_resources+=yaml_info['JivaProductionTestSuite']
    else:
        print('Key: JivaProductionTestSuite not provided. Moving on...')
    if 'JivaDevelopmentTestSuite' in yaml_info and yaml_info['JivaDevelopmentTestSuite'] is not None:
        jiva_plan_resources+=yaml_info['JivaDevelopmentTestSuite']
    else:
        print('Key: JivaDevelopmentTestSuite not provided. Moving on...')
    print("Creating test plans")

    if len(jiva_plan_resources)>0:
        S = ruamel.yaml.scalarstring.DoubleQuotedScalarString
        map_src_id['jiva_plan_run_id'], case_resources, jiva_test_yaml = create_test_plan(client, args, "JIVA", project_id), [], []
        
        for suites in jiva_plan_resources:
            for suite_name, suite_info in suites.items():
                suite_run_id, case_resource = add_suites(map_src_id["jiva_plan_run_id"], suite_name, client, suite_info, project_id)
                map_src_id['jiva'][suite_name]=suite_run_id
                case_resources += case_resource

        if len(case_resources)>0:
            jiva_test_yaml+=[
                {
                    "tasks": [
                        {
                            "when": "slack_notify | bool and lookup('env','SLACK_TOKEN')",
                            "slack": {
                                "msg": "{{ ansible_date_time.time }} OPENEBS TESTSUITE STARTED - JIVA",
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
            for case_resource in case_resources:
                if case_resource['path'] is None or len(case_resource['path'])<=0:
                    continue
                jiva_test_yaml.append({'include': case_resource['path'],  'vars': {'status_id':S(''),'testname':S(''),'flag':S(''),'cflag':S(''),'storage_engine': S('jiva'),'status': S('')}})
                jiva_test_yaml.append({'hosts': 'localhost',
                    'tasks': [{'include_tasks': S('{{utils_path}}/update-status.yml'),
                    'vars': {'c_status': S('{{ cflag }}'),
                        'case_id': case_resource['case_id'],
                        'st_id': S('{{ status_id }}'),
                        'suite_id': case_resource['suite_id'],
                        't_status': S('{{ flag }}'),
                        't_name': S('{{ testname }}'),
                        'storage_engine': S('jiva'),
                        'color': S('{{ status }}')
                        }}]})

            jiva_test_yaml += [
                    {
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
                                        "attachments": [
                                            {
                                                "title": "JIVA Build #" +str(args['build_number'])+" completed",
                                                "title_link": "https://cloudbyte.testrail.com/index.php?/runs/view/"+str(map_src_id['jiva_plan_run_id']),
                                                "text": "*Username:* username\n*Password:* Password",
                                                "color": "#439FE0",
                                                "mrkdwn_in": ["text"]
                                            }
                                        ],
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
                    }
                ]

            tyaml= ruamel.yaml.YAML()
            tyaml.dump(jiva_test_yaml,stream=open("../jiva-run-tests.yml",'w+'))
            ci_yaml.append({'include': 'jiva-run-tests.yml'})
            # _, err = write_file("../jiva-run-tests.yml", yaml.dump(jiva_test_yaml, default_flow_style=False))
            # if err == -1:
            #     exit(err)

        print("Jiva plan created")
    else:
        print("Jiva plan creation failed")

    if len(cstor_plan_resources)>0:
        S = ruamel.yaml.scalarstring.DoubleQuotedScalarString
        map_src_id["cstor_plan_run_id"], case_resources, cstor_test_yaml = create_test_plan(client, args, "CSTOR", project_id), [], []
        for suites in cstor_plan_resources:
            for suite_name, suite_info in suites.items():
                suite_run_id, case_resource = add_suites(map_src_id["cstor_plan_run_id"], suite_name, client, suite_info, project_id)
                map_src_id['cStor'][suite_name]=suite_run_id
                case_resources+=case_resource
        
        if len(case_resources)>0:
            cstor_test_yaml += [
                {
                    "tasks": [
                        {
                            "when": "slack_notify | bool and lookup('env','SLACK_TOKEN')",
                            "slack": {
                                "msg": "{{ ansible_date_time.time }} OPENEBS TESTSUITE STARTED - CSTOR",
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

            for case_resource in case_resources:
                if case_resource['path'] is None or len(case_resource['path'])<=0:
                    continue
                cstor_test_yaml.append({'include': case_resource['path'], 'vars': {'status_id':S(''),'testname':S(''),'flag':S(''),'cflag':S(''),'storage_engine': S('cStor'),'status': S('')}})
                cstor_test_yaml.append({'hosts': 'localhost',
                    'tasks': [{'include_tasks': S('{{utils_path}}/update-status.yml'),
                    'vars': {'c_status': S('{{ cflag }}'),
                        'case_id': case_resource['case_id'],
                        'st_id': S('{{ status_id }}'),
                        'suite_id': case_resource['suite_id'],
                        't_status': S('{{ flag }}'),
                        't_name': S('{{ testname }}'),
                        'storage_engine': S('cStor'),
                        'color': S('{{ status }}')
                        }}]})

            cstor_test_yaml += [
                    {
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
                                        "attachments": [
                                            {
                                                "title": "CSTOR Build #" +str(args['build_number'])+" completed",
                                                "title_link": "https://cloudbyte.testrail.com/index.php?/runs/view/"+str(map_src_id['cstor_plan_run_id']),
                                                "text": "*Username:* test@openebs.io\n*Password:* openebs",
                                                "color": "#439FE0",
                                                "mrkdwn_in": ["text"]
                                            }
                                        ],
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
                    }
                ]
            tyaml= ruamel.yaml.YAML()
            tyaml.dump(cstor_test_yaml,stream=open("../cstor-run-tests.yml",'w+'))
            ci_yaml.append({'include': 'cstor-run-tests.yml'})
        # _, err = write_file("../cstor-run-tests.yml", tyaml.dump(cstor_test_yaml, sys.stdout.write))
        # if err == -1:
        #     exit(err)

        print("Cstor plan created")
    else:
        print("Cstor plan creation failed")
    
    for item in ci_info['include_after']:
        ci_yaml.append({'include': item})
    _, err = write_file("../ci.yml", yaml.dump(ci_yaml, default_flow_style=False))
    if err == -1:
        exit(err)

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
