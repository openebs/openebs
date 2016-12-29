
## Installing from binaries

An OpenEBS Cluster comprises of OpenEBS Maya Masters (omm) for storing the metadata and orchestrating the VSMs on the OpenEBS Storage Hosts (osh). The OpenEBS Storage Hosts typically would either have hard disks/SSDs or mounted file/block/s3 storage that will be used as persistent store.

OpenEBS binary (maya) releases are maintained in github at https://github.com/openebs/maya/releases

**maya** is a single binary that will be installed on the machine, which can later pull in the dependendcies from githup or dockerhub. 

OpenEBS Storage is delivered through containers called VSMs. The docker image (called as **jiva**) for the containers are distributed from Dockerhub https://hub.docker.com/r/openebs/jiva/


### (1) Prepare the VM or Physical Host for installing OpenEBS Maya Master or Storage Host

We recommend using 64 bit platform with Ubuntu 16.04 installed. Configure the network on the machine, so that it can download the released binaries and has the ability to download the required dependencies from github and dockerhub. There are no specific limits enforced on the system resources like RAM, CPU or Storage, but as a best practice we recommend that Storage Hosts be appropriately sized for the storage it serves. 

The following are the only requirements for installation:
- ubuntu 16.04
- (optional) wget or curl - for downloading the binary
- unzip package is mandatory 
- Internet connectivity is enabled. 

If the machine has more than one IP address, note down the IP address that you would want your omm/osh to communicate with each other. 

### (2) Download and install from binary

Download the required release to download from https://github.com/openebs/maya/releases

You can download using wget as follows:
```
RELEASE_TAG=0.0.3
wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip
```
### (3) Verify maya is installed

Ensure you can run **maya**. 
```
maya version
```

### (4) Configure and start OpenEBS Maya Master (omm)
```
ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.3
```

### (5) Configure and start OpenEBS Storage Host (osh)

```
ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.6 -omm-ips=172.28.128.3
```

