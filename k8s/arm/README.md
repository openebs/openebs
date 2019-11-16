# Building OpenEBS for ARM

OpenEBS runs in user space and does not have any Linux kernel module dependencies. This makes OpenEBS an ideal candidate for easily generating binaries and container images for ARM machines. The community is helping with refactoring the OpenEBS build scripts to make it easy to generate ARM binaries and container images. The efforts are lead by @Wangzihao18 @kmova. If you would like to help out with these efforts please reach out over [OpenEBS Slack #arm](https://openebs-community.slack.com/) channel. 

ARM support is still under active development. As of 1.4.0, you can run OpenEBS Jiva and Local PVs on ARM. The steps below provide instructions on how to build the components for Jiva and Local PVs. 

## Prerequisites

The steps provided here assume that you have a ARM node that has the following installed:
- Go 1.12.5 or higher
- Docker 17.09 or higher

Some of the below components might require additional dependencies to be installed. 

## Building NDM

NDM uses cgo to interact with libudev and seachest libraries for discovering device attributes. Prior to building NDM, setup the build tools using the instructions mentioned [here](https://github.com/openebs/node-disk-manager#build-image).

NDM images can be built using the following. You can change the default container used for NDM using the `BASE_DOCKER_IMAGEARM64` ENV variable.

```
cd $GOPATH/src/github.com/openebs
git clone https://github.com/openebs/node-disk-manager.git
export BASE_DOCKER_IMAGEARM64=arm64v8/ubuntu:18.04 
make
```

The above steps will create the following docker images:
- openebs/node-disk-operator-arm64:ci
- openebs/node-disk-manager-arm64:ci

Tag the images and push to your repo. The following steps are used to push the alpha versions of this image to openebs docker repo. 

```
sudo docker tag openebs/node-disk-operator-arm64:ci openebs/node-disk-operator-arm64-ci:v0.4.4
sudo docker tag openebs/node-disk-manager-arm64:ci openebs/node-disk-manager-arm64-ci:v0.4.4
sudo docker push openebs/node-disk-operator-arm64-ci:1.4.0
sudo docker push openebs/node-disk-manager-arm64-ci:1.4.0
```

NDM uses linux-utils to image to launch a kubernete job to cleanup devices after being released from PV. The image can be build and pushed as follows:

```
mkdir $GOPATH/litmuschaos
cd $GOPATH/litmuschaos
git clone https://github.com/litmuschaos/test-tools.git
cd linux-utils && docker build -t openebs/linux-utils .
sudo docker tag openebs/linux-utils:latest openebs/linux-utils:arm64-1.4.0
sudo docker push openebs/linux-utils:arm64-1.4.0
```

## Building Jiva Provisioner

```
cd $GOPATH/src/github.com/kubernetes-incubator
git clone https://github.com/openebs/external-storage.git
cd external-storage
git checkout release
cd openebs; export BASE_DOCKER_IMAGEARM64=arm64v8/ubuntu:16.04; make image.arm64
```

Tag the provisioner image and push to your repo. 

```
sudo docker tag openebs/openebs-k8s-provisioner-arm64:ci openebs/openebs-k8s-provisioner-arm64-ci:1.4.0
sudo docker push openebs/openebs-k8s-provisioner-arm64-ci:1.4.0
```

## Building Jiva Data Engine

```
cd $GOPATH/src/github.com/openebs
git clone https://github.com/openebs/jiva.git
cd jiva
export BASE_DOCKER_IMAGEARM64=arm64v8/ubuntu:16.04; make build
```

Note: some of the e2e tests fail after the jiva image is built. You can abort the build process, after seeing the message that image has been built. 

The jiva images are tagged with commit id. Find the jiva images that was just built using:
```
sudo docker images | grep jiva
```

Let us say the image is `openebs/jiva-arm64:dev-7fcc4cd`. Tag and push this image to your repo. 
```
sudo docker tag openebs/jiva-arm64:dev-7fcc4cd openebs/jiva-arm64-ci:1.4.0
sudo docker push openebs/jiva-arm64-ci:1.4.0
```


## Building OpenEBS API Server and Local PV Dynamic Provisioner

```
cd $GOPATH/src/github.com/openebs
git clone https://github.com/openebs/maya.git
cd maya
make bootstrap
export BASE_DOCKER_IMAGEARM64=arm64v8/ubuntu:16.04;make all.arm64
```

The above steps will create the following docker images:
- openebs/m-apiserver-arm64:ci
- openebs/provisioner-localpv-arm64:ci

Tag and push to your repo. 

```
sudo docker tag openebs/m-apiserver-arm64:ci openebs/m-apiserver-arm64-ci:1.4.0
sudo docker tag openebs/provisioner-localpv-arm64:ci openebs/provisioner-localpv-arm64-ci:1.4.0
sudo docker push openebs/m-apiserver-arm64-ci:1.4.0
sudo docker push openebs/provisioner-localpv-arm64-ci:1.4.0
```

## Future Development Items
- Refactor the build scripts for prometheus exporter  (m-exporter)
- Refactor the build scripts for openebs-tools used by NDM and Local Provisioner
- Setup e2e tests on Jiva Data Engine and Local PV
- Refactor the build scripts cStor Data Engine
- Setup e2e tests on cStor
- Automating commit and release builds
- Adding e2e pipeline for ARM builds. 

## Help Required
- Hardware access to build/test various flavors of ARM build 
- Hardware access to setup Kubernetes ARM clusters and run e2e tests.
- New contributors to help with above mentioned development items

