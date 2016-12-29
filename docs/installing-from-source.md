
## Installing from binaries

Pre-requisites : ubuntu 16.04, wget, unzip

```
RELEASE_TAG=0.0.3
wget https://github.com/openebs/maya/releases/download/${RELEASE_TAG}/maya-linux_amd64.zip
unzip maya-linux_amd64.zip
sudo mv maya /usr/bin
rm -rf maya-linux_amd64.zip
```

