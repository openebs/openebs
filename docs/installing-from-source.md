
## Installing from source

Pre-requisites : ubuntu 16.04, git, zip, unzip, go. 

```
mkdir -p $GOPATH/src/github.com/openebs && cd $GOPATH/src/github.com/openebs
git clone https://github.com/openebs/maya.git
cd maya && make dev
```


### Setup and Initialize 

Setup OpenEBS Master and Host Nodes by logging into the nodes via ssh. When there are multiple IPs on the node, you can specify the listening ip for the node via **-self-ip**

#### Setup OpenEBS Maya Master (omm)

maya setup-omm [-self-ip=<listen ip address>]

Example:
```
ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.3
```

#### Setup OpenEBS Host (osh)

maya setup-osh -omm-ips=172.28.128.3 [-self-ip=<listen ip address>]

```
ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.6 -omm-ips=172.28.128.3
```

