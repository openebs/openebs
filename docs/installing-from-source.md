
## Installing from source

An OpenEBS Cluster comprises of OpenEBS Maya Masters (omm) for storing the metadata and orchestrating the VSMs on the OpenEBS Storage Hosts (osh). The OpenEBS Storage Hosts typically would either have hard disks/SSDs or mounted file/block/s3 storage that will be used as persistent store.

**maya** is the only binary that needs to be installed on the machine to turn the machine in to either **omm** or **osh**. Maya will pull in the dependencies from githup or dockerhub as required. You need to have the machine connected to internet while running the *setup* commands. 

### Software Requirements

On your machine, ensure the following:
- **golang** is installed. Verify $GOPATH environment variable is set and $GOPATH/bin is included in your $PATH
- **git** is installed for downloading the source
- **zip** and **unzip** packages are required for creating and distributing the depedencies 

### Download Source, Compile and Install maya
```
mkdir -p $GOPATH/src/github.com/openebs && cd $GOPATH/src/github.com/openebs
git clone https://github.com/openebs/maya.git
cd maya && make dev
```

### Verify maya is running
```
maya
```

### Setup OpenEBS Maya Master (omm)

```
ubuntu@master-01:~$ maya setup-omm -self-ip=172.28.128.3
```

### Setup OpenEBS Host (osh)

```
ubuntu@host-01:~$ maya setup-osh -self-ip=172.28.128.6 -omm-ips=172.28.128.3
```

