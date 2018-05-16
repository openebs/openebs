# OpenEBS

[![Build Status](https://img.shields.io/travis/openebs/openebs/master.svg?style=flat-square)](https://travis-ci.org/openebs/jiva)
[![Docker Pulls](https://img.shields.io/docker/pulls/openebs/jiva.svg?style=flat-square)](https://hub.docker.com/r/openebs/jiva/)
[![Releases](https://img.shields.io/github/release/openebs/openebs/all.svg?style=flat-square)](https://github.com/openebs/openebs/releases)
[![Slack](https://img.shields.io/badge/chat!!!-slack-ff1493.svg?style=flat-square)]( https://openebsslacksignup.herokuapp.com/)
[![Twitter](https://img.shields.io/twitter/follow/openebs.svg?style=social&label=Follow)](https://twitter.com/intent/follow?screen_name=openebs)

http://www.openebs.io/
 
OpenEBS enables the use of containers for mission critical, persistent workloads.  OpenEBS is containerized storage and related storage services.   
 
OpenEBS allows you to treat your persistent workload containers, such as DBs on containers, just like other containers.  OpenEBS itself is deployed as just another container on your host, and enables storage services that can be designated on a per pod, application, cluster or container level, including:   
- Data persistence across nodes, dramatically reducing time spent rebuilding Cassandra rings for example
- Synchronization of data across availability zones and cloud providers
- Use of commodity hardware plus a container engine to deliver seriously scale out block storage
- Integration with orchestrators, so that developer and application intent flows into OpenEBS configurations automatically
- Management of tiering to and from S3 and other targets
- Plus we are bringing our experience from BSD based containerization and delivering QoS for customers from our CloudByte experience over to OpenEBS - expect to see more intelligence and manageability 
  
Our vision is simple: let us let storage and storage services for persistent workloads be so fully integrated into the environment and hence managed automatically that it almost disappears into the background as just yet another infrastructure service that works.  
 
## Why OpenEBS Scales
 
OpenEBS can scale to include an  arbitrarily large number of containerized storage controllers. Thanks in part to some advancements in the metadata management which removes a common bottleneck to scale out storage performance. Again, we learnt the hard way over the years at CloudByte and are extremely happy to see initial scale out performance figures with OpenEBS; much credit goes to the orchestration and containerization as well.
 
## Installation and Getting Started
 
OpenEBS can be setup in few easy steps.  You can get going on your choice of Kubernetes cluster by having open-iscsi installed on the Kubernetes nodes and running the openebs-operator using kubectl. 

**Start the OpenEBS Services using Operator**
```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-operator.yaml
kubectl apply -f openebs-operator.yaml
```
**Customize or use the Default storageclasses**
```
wget https://raw.githubusercontent.com/openebs/openebs/master/k8s/openebs-storageclasses.yaml
kubectl apply -f openebs-storageclasses.yaml
```
You could also follow our [QuickStart Guide](https://docs.openebs.io/docs/overview.html).

OpenEBS can be deployed on any Kubernetes cluster - either in cloud, on-premise or developer laptop (minikube). Please follow our [OpenEBS Setup](https://docs.openebs.io/docs/overview.html) documentation. Also, we have a Vagrant environment available that includes a sample Kubernetes deployment and synthetic load that you can use to simulate the performance of OpenEBS. 

## Deploying kube-state-metrics

Install this project to your ```$GOPATH``` using go get:

```go get k8s.io/kube-state-metrics```
### Building the Docker container

Simple run the following command in this root folder, which will create a self-contained, statically-linked binary and build a Docker image: 

```make container```
### Usage

Simply build and run kube-state-metrics inside a Kubernetes pod which has a service account token that has read-only access to the Kubernetes cluster.  

### Kubernetes Deployment

To deploy this project, you can simply run ```kubectl apply -f kubernetes``` and a Kubernetes service and deployment will be created. (Note: Adjust the apiVersion of some resource if your kubernetes cluster's version is not 1.8+, check the yaml file for more information). The service already has a ```prometheus.io/scrape: 'true'``` annotation and if you added the recommended Prometheus service-endpoint scraping configuration, Prometheus will pick it up automatically and you can start using the generated metrics right away.

*Note*: Google Kubernetes Engine (GKE) Users - GKE has strict role permissions that will prevent the kube-state-metrics roles and role bindings from being created. To work around this, you can give your GCP identity the cluster-admin role by running the following one-liner:
  
```kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud info | grep Account | cut -d '[' -f 2 | cut -d ']' -f 1)```

After running the above, if you see ```Clusterrolebinding "cluster-admin-binding"``` created, then you are able to continue with the setup of this service.

### Development

When developing, test a metric dump against your local Kubernetes cluster by running:

    Users can override the apiserver address in KUBE-CONFIG file with --apiserver command line.

```go install kube-state-metrics --port=8080 --telemetry-port=8081 --kubeconfig=<KUBE-CONFIG> --apiserver=<APISERVER>``` 

Then curl the metrics endpoint

```curl localhost:8080/metrics```

 
## Status
We are approaching beta stage with active development underway. See our [Project Tracker](https://github.com/openebs/openebs/wiki/Project-Tracker) for more details.
 
## Contributing
 
We welcome your feedback and contributions in any form possible.  
 
- Join us at [Slack](https://openebsslacksignup.herokuapp.com/)
  - Already signed up? Head to our discussions at [#openebs-users](https://openebs-community.slack.com/messages/openebs-users/)
- Want to raise an issue?
  - If it is a generic (or `not really sure`), you can still raise it at [issues](https://github.com/openebs/openebs/issues)
  - Project (repository) specific issues also can be raised at [issues](https://github.com/openebs/openebs/issues) and tagged with the individual repository labels like *repo/maya*.
- Want to help with fixes and features?
  - See [open issues](https://github.com/openebs/openebs/labels)
  - See [contributing guide](./CONTRIBUTING.md)

## Show me the Code

This is a meta-repository for OpenEBS. Here, [openebs/openebs](https://github.com/openebs/openebs), please find various documentation related artifacts, e2e tests and code related to deploying OpenEBS with popular orchestration engines like Kubernetes, Swarm, Mesos, Rancher, and so on. The source code is available at the following locations:
- The core storage source code is under [openebs/jiva](https://github.com/openebs/jiva).
- The storage orchestration source code is under [openebs/maya](https://github.com/openebs/maya).
- While *jiva* and *maya* contain significant chunks of source code, some of the orchestration and automation code is also distributed in other repositories under the OpenEBS organization. 

Please start with the pinned repositories or with [OpenEBS Architecture](./contribute/design/README.md) document. 


## License

OpenEBS is developed under Apache 2.0 License at the project level. 
Some components of the project are derived from other open source projects like Nomad, Longhorn 
and are distributed under their respective licenses. 
