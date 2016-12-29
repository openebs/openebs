
## Installing from binaries

Pre-requisites : ubuntu 16.04, wget, unzip

```
RELEASE_TAG=0.0.3
wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip
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

