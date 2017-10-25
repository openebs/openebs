## Overview
* [Prometheus](https://github.com/prometheus/prometheus) is a monitoring tool  which is used to monitor OpenEBS volumes. There is already a lot of exporters like [node-exporter](https://github.com/prometheus/node_exporter) are available which can be used to gather the various metrics. 
* This subdir has two files
    - prometheus.yaml
    - prometheus-operator.yaml
* prometheus.yaml :  This is the configuration file for prometheus, which can be used by prometheus to get the targets (Where to collect metrics?) and it displays the collected metrics in Prometheus expression browser.
* prometheus-operator.yaml : This is the operator file for prometheus which is used to launch prometheus and it's components on [Kubernetes](https://github.com/kubernetes/kubernetes) cluster.

## Prerequisits
* Please go through the steps mentioned in [k8s/vagrant](https://github.com/openebs/openebs/tree/master/k8s/vagrant) subdir .

## Setup Prometheus

Fetch the latest prometheus-operator.yaml
```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/prometheus.yaml
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-monitoring/prometheus-operator.yaml
```
Create configmap and launch prometheus-operator on your kubernetes cluster
```
kubectl create -f prometheus.yaml
kubectl create -f prometheus-operator.yaml
```
## Verify
After Successful run of the above commands  you will see output like below :
```
ubuntu@kubemaster-01:~$ kubectl create -f prometheus.yaml 
configmap "prometheus-config" created
ubuntu@kubemaster-01:~$ kubectl create -f prometheus-operator.yaml
serviceaccount "prometheus" created
clusterrole "prometheus" created
clusterrolebinding "prometheus" created
deployment "prometheus-deployment" created
service "prometheus-service" created
daemonset "node-exporter" created
```
## Launch Prometheus Expression Browser
* Do `kubectl cluster-info` to get the NodeIP
* Open NodeIP:32514/targets in your Browser  and it will launch prometheus expression browser.
