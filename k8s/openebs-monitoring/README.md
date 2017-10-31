## Overview
* OpenEBS use [Prometheus](https://github.com/prometheus/prometheus) to  monitor Volumes . We use [node-exporter](https://github.com/prometheus/node_exporter) to gather nodes metrics, [cadviser](https://github.com/google/cadvisor) for containers metrics and maya-agent to gather OpenEBS volume's metrics. 
* This sub directory has following files:
├── openebs-monitoring
│   ├── alertmanager.yaml
│   ├── configs
│   │   ├── alertmanager-config.yaml
│   │   ├── alertmanager-templates.yaml
│   │   ├── prometheus-alert-rules.yaml
│   │   ├── prometheus-config.yaml
│   │   └── prometheus-env.yaml
│   ├── grafana-operator.yaml
│   ├── prometheus-operator.yaml
│   └── README.md

    * alertmanager.yaml : This is for creating deployment and service of alertmanager.
    * alertmanager-config : This is configuration file for alertmanager, used to load templates and to set alerts in slack. This can be configured to to set alerts at various platforms like e-mail, slack etc.
    * alertmanager-templates.yaml : This is used to customize notifications send to slack.
    * prometheus-alert-rules.yaml: Rules defined for alerting is passed  in prometheus-deployment.
    * prometheus-config.yaml :  This is  configuration file for prometheus, which can be used by prometheus to receive the targets and it displays the collected metrics in the Prometheus expression browser.
    * prometheus-env: This is to store all the necessary runtime arguments to Prometheus.
    * grafana-operator.yaml : This file is to create deployment and start service of grafana for various monitoring and analytics.
    * prometheus-operator.yaml : This is the operator file for prometheus which is used to launch prometheus and it's components on [Kubernetes](https://github.com/kubernetes/kubernetes) cluster.

## Prerequisits
* Go through the procedure given in [k8s/vagrant](https://github.com/openebs/openebs/tree/master/k8s/vagrant) subdir .

## Setup Prometheus

Fetch the latest prometheus-operator.yaml
```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/configs/prometheus-config.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/prometheus-operator.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/configs/prometheus-alert-rules.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/configs/alertmanager-config.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/configs/alertmanager-templates.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/configs/prometheus-env.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/alertmanager.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/grafana-operator.yaml

```
Create configmap and launch prometheus-operator on your Kubernetes cluster
```
kubectl create -f prometheus-config.yaml
kubectl create -f prometheus-env.yaml
kubectl create -f prometheus-alert-rules.yaml
kubectl create -f alertmanager-templates.yaml
kubectl create -f alertmanager-config.yaml
kubectl create -f prometheus-operator.yaml
kubectl create -f alertmanager.yaml
kubectl create -f grafana-operator.yaml
```
## Verify
After Successfully running the above commands, the output displayed is similar to the following :
```
configmap "prometheus-config" created
configmap "prometheus-env" created
configmap "prometheus-alert-rules" created
configmap "alertmanager-templates" created
configmap "alertmanager-config" created

serviceaccount "prometheus" created
clusterrole "prometheus" created
clusterrolebinding "prometheus" created
deployment "prometheus-deployment" created
service "prometheus-service" created
daemonset "node-exporter" created

deployment "alertmanager" created
service "alertmanager" created

service "grafana" created
deployment "grafana" created
```
## Launch Prometheus Expression browser
* Run `kubectl cluster-info` to get the NodeIP
* Open NodeIP:32514/targets in your Browser  and it will launch prometheus expression browser.
## Launch Grafana UI
* Run `kubectl get svc` and note down the NodePort, used to launch UI of grafana and alertmanager.
* To launch grafana open NodeIP:NodePort  (NodePort of grafana service) in your browser.
## Launch Alertmanager UI
* To launch alertmanager open NodeIP:NodePort (NodePort of alertmanager service)
