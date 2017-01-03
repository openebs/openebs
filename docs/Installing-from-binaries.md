
## Install Maya

**maya** is a single binary that will be installed on both OpenEBS Maya Master (OMM) and OpenEBS Storage Host (OSH) machines. Maya can then be used to configure the machine either as omm or osh. Maya will pull in the dependencies from github or dockerhub. OpenEBS binary (maya) releases are maintained in github at https://github.com/openebs/maya/releases

Before proceeding to install maya, verify that wget and unzip packages are installed. 

```
RELEASE_TAG=0.0.4
wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip
maya version
```

If you can see the maya version, you are all set to go!


### (4) Configure and start OpenEBS Maya Master (omm)
```
ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.3
```

### (5) Configure and start OpenEBS Storage Host (osh)

```
ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.6 -omm-ips=172.28.128.3
```

