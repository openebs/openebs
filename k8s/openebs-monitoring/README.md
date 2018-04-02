## Overview
* OpenEBS uses [Prometheus](https://github.com/prometheus/prometheus) to  monitor Volumes . We use [node-exporter](https://github.com/prometheus/node_exporter) to gather nodes metrics, [cadviser](https://github.com/google/cadvisor) for container metrics and maya-agent to gather OpenEBS volume's metrics.
* [openebs-monitoring](https://github.com/openebs/openebs/tree/master/k8s/openebs-monitoring) sub directory has following files:
```
├── openebs-monitoring
│   ├── alertmanager.yaml
│   ├── configs
│   │   ├── alertmanager-config.yaml
│   │   ├── alertmanager-templates.yaml
│   │   ├── openebs-dashboard.json
│   │   ├── prometheus-alert-rules.yaml
│   │   ├── prometheus-config.yaml
│   │   └── prometheus-env.yaml
│   ├── federation
│   │   ├── configs
│   │   │   ├── alertmanager-config.yaml
│   │   │   ├── alertmanager-templates.yaml
│   │   │   ├── openebs-dashboard.json
│   │   │   ├── prometheus-alert-rules.yaml
│   │   │   ├── prometheus-config-master.yaml
│   │   │   └── prometheus-env.yaml
│   │   ├── grafana-operator.yaml
│   │   └── prometheus-operator-master.yaml
│   ├── grafana-operator.yaml
│   ├── prometheus-operator.yaml
│   └── README.md
```


**alertmanager.yaml:** This file is for creating deployment and alertmanager service.

**alertmanager-config.yaml:** This is a configuration file for alertmanager, used to load templates and to set alerts in slack. This can be configured to set alerts at various platforms like e-mail, slack and so on.

**alertmanager-templates.yaml:** This file is used to customize notifications sent to slack.

**prometheus-alert-rules.yaml:** Rules defined for alerting is passed  in prometheus-deployment.

**prometheus-config.yaml:**  This is a configuration file for prometheus, which can be used by prometheus to receive the targets and it displays the collected metrics in the Prometheus expression browser.

**prometheus-env.yaml:** This file stores all the run time arguments for Prometheus.

**grafana-operator.yaml:** This file creates deployment and starts grafana service for various monitoring and analytics processes.

**prometheus-operator.yaml:** This is the operator file for prometheus which is used to launch prometheus and it's components on [Kubernetes](https://github.com/kubernetes/kubernetes) cluster.

## Prerequisits
* Go through the procedure given in [k8s/vagrant](https://github.com/openebs/openebs/tree/master/k8s/vagrant) subdirectory.

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
Create configmap and launch prometheus-operator on your Kubernetes cluster.
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

- **Note** : For setting up the cluster on gcloud change the type of service
    from NodePort to LoadBalancer, ClusterIP based on your requirement. Choosing
    NodePort over LoadBalancer and ClusterIP doesn't gives you external IP
    rather exposed srvices can be accesible on the NodeIP:NodePort.
## Verify
After successfully running the above commands, the output displayed is similar to the following :
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
## Launch Prometheus Expression Browser
* Run `kubectl cluster-info` to get the NodeIP
* Open NodeIP:32514/targets in your Browser  and it will launch prometheus expression browser.
## Launch Grafana UI
* Run `kubectl get svc` and note down the NodePort, used to launch Grafana User Interface and Alertmanager.
* To launch Grafana open NodeIP:NodePort  (NodePort of grafana service) in your browser.
* After login add your data source by putting IP address of Prometheus to import the dashboard
* These are the graphs related to prometheus. You can create a new dashboard by importing `openebs-dashboard.json`
## Launch Alertmanager UI
* To launch alertmanager open NodeIP:NodePort (NodePort of alertmanager service)

## Federation
Federation is used for scaling prometheus and ensuring its reliability. In this configuration there are two or more than two Prometheus running instances one is known as global which is used for collecting the metrics from others, known as slaves.
## Setup Federation
* All the setups and steps are very similar to previous one, one and only change is to be made in prometheus-master-config.yaml.
* Just replace the IP given in targets field of job `master-federation` with your slave prometheus and also add the job name which you want to collect in the match field.
* After configuring your global prometheus just repeat the steps given above in setup prometheus.

### Note : 
**if you are using openebs version > 0.5 then m-exporter runs as sidecar in jiva in the subsequent versions, so you need not to create a separate deployment for that.**
