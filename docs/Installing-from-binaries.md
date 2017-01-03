
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

### Setup OpenEBS Maya Master (OMM)

Verify that maya is installed and obtain the Listen IP address for Maya Master. The maya cli will connect to this IP address for scheduling and managing the VSMs.

```
ubuntu@master-01:~$ maya version
Maya v'0.0.4'-dev ('6fe624e3bc71c0b053795939511eff00a18c10f3')
ubuntu@master-01:~$ ip addr show | grep global
    inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
    inet 172.28.128.8/24 brd 172.28.128.255 scope global enp0s8
ubuntu@master-01:~$ 
```

Let us use the 172.28.128.8 as the listen IP address. Configure the machine as OMM with the following instruction.

```
ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.8
```

Verify that Maya Master is configured by running the following command:

```
ubuntu@master-01:~$ maya omm-status
Name              Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
master-01.global  172.28.128.8  4648  alive   true    2         0.5.0  dc1         global
ubuntu@master-01:~$ 
```

### Setup OpenEBS Storage Host (OSH)

Verify that maya is installed and obtain the Listen IP address for Maya Master. The maya cli will connect to this IP address for scheduling and managing the VSMs.

```
ubuntu@host-01:~$ maya version
Maya v'0.0.4'-dev ('6fe624e3bc71c0b053795939511eff00a18c10f3')
ubuntu@host-01:~$ ip addr show | grep global
    inet 10.0.2.15/24 brd 10.0.2.255 scope global enp0s3
    inet 172.28.128.9/24 brd 172.28.128.255 scope global enp0s8
ubuntu@host-01:~$ 
 
```

Let us use the 172.28.128.9 as the listen IP address and connect to the previously installed Maya Master at 172.28.128.8 Configure the machine as OSH with the following instruction. 

```
ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.9 -omm-ips=172.28.128.8
```

Verify that Storage Host is configured by running the following command:

```
ubuntu@host-01:~$ maya osh-status
ID        DC   Name     Class   Drain  Status
dc7fd9b9  dc1  host-01  <none>  false  ready
ubuntu@host-01:~$ 
```

Repeat the same steps on the host-02 as well. 

### Verify configuration

On successful completion, the omm-status should show one entry and osh-status should have two entries. The output should look like below:

```
ubuntu@master-01:~$ maya omm-status
Name              Address       Port  Status  Leader  Protocol  Build  Datacenter  Region
master-01.global  172.28.128.8  4648  alive   true    2         0.5.0  dc1         global
ubuntu@master-01:~$ maya osh-status
ID        DC   Name     Class   Drain  Status
cbceb3d2  dc1  host-02  <none>  false  ready
dc7fd9b9  dc1  host-01  <none>  false  ready
ubuntu@master-01:~$ 
```
