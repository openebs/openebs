# Introduction

This document lists down various commands used by OpenEBS
daemon for various management activities like container management,
storage management, etc.

## Commands w.r.t VSM (as an LXC)

### Create a new VSM

```shell
# name = name of the lxc
# none implies no image/template

lxc-create -n $(name) -t none
```

### Create the root filesystem for the created VSM

```shell

# unzips a custom openebs image into rootfs
# applies permission to ssh files

mkdir /var/lib/lxc/$(name)/rootfs
tar -zxf /etc/openebs/base.tar.gz -C /var/lib/lxc/$(name)/rootfs/
chmod 600 /var/lib/lxc/$(name)/rootfs/etc/ssh/ssh_host_rsa_key
chmod 600 /var/lib/lxc/$(name)/rootfs/etc/ssh/ssh_host_ecdsa_key
chmod 600 /var/lib/lxc/$(name)/rootfs/etc/ssh/ssh_host_ed25519_key
mkdir -p /var/lib/lxc/$(name)/rootfs/var/empty/sshd/

```

### Create a config for the created VSM

```shell

LXC_CONF_PATH        := /var/lib/lxc/$(name)/config

echo "lxc.network.type = phys"               > $(LXC_CONF_PATH)
echo "lxc.network.flags = up"                >> $(LXC_CONF_PATH)
echo "lxc.network.link = $(interface)"       >> $(LXC_CONF_PATH)
echo "lxc.network.ipv4 = $(ip)/$(subnet)"    >> $(LXC_CONF_PATH)
echo "lxc.network.ipv4.gateway = $(router)"  >> $(LXC_CONF_PATH)
echo "lxc.mount.entry = /dev /var/lib/lxc/$(name)/rootfs/dev none bind 0 0" >> $(LXC_CONF_PATH)

# ?? storage pool that this LXC will use
mkdir -p $(storage)/$(name)
mkdir -p /var/lib/lxc/$(name)/rootfs/openebs

echo "lxc.mount.entry = $(storage)/$(name) /var/lib/lxc/$(name)/rootfs/openebs none bind 0 0" >> $(LXC_CONF_PATH)
echo "lxc.rootfs = /var/lib/lxc/$(name)/rootfs"                >> $(LXC_CONF_PATH)
echo "lxc.include = /usr/share/lxc/config/centos.common.conf"  >> $(LXC_CONF_PATH)
echo "lxc.arch = x86_64"                     >> $(LXC_CONF_PATH)
echo "lxc.utsname = $(name)"                 >> $(LXC_CONF_PATH)
echo "lxc.autodev = 1"                       >> $(LXC_CONF_PATH)
echo "lxc.kmsg = 0"                          >> $(LXC_CONF_PATH)
```

### Set LXC's network & start the LXC

```shell

ip addr add $(ip)/$(subnet) dev $(interface)
lxc-start -n $(name) -d
sleep $(SLEEP_SECS)

```

## Commands w.r.t VSM (via LXC) and Storage (via CFS)

### Start the tgtd service

```shell

# name refers to the name of the LXC

lxc-attach -n $(name) -- service tgtd start
sleep $(SLEEP_SECS)
```

### Create a volume

```shell

# name refers to the name of the LXC

# create a volume as an iscsi target
lxc-attach -n $(name) -- tgtadm --lld iscsi --op new --mode target --tid 1 -T iqn.2016-07.com.cb:openebs.disk.$(volume)

# ?? Probably not required as it is already created & mounted to the storage pool
lxc-attach -n $(name) -- mkdir -p /openebs

# set properties of the iscsi target
lxc-attach -n $(name) -- tgtadm --lld iscsi --op new --mode logicalunit --tid 1 --lun 1 --blocksize 4096 --bstype cfs -b /openebs/$(volume)

# ??
lxc-attach -n $(name) -- tgtadm --lld iscsi --op bind --mode target --tid 1 -I ALL
```
