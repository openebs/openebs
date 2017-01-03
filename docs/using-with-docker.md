# Configuring Docker with OpenEBS Storage


```
ubuntu@client-01:~$ sudo iscsiadm -m discovery -t st -p 172.28.128.101:3260
172.28.128.101:3260,1 iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1
ubuntu@client-01:~$ sudo iscsiadm -m node -l
Logging in to [iface: default, target: iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1, portal: 172.28.128.101,3260] (multiple)
Login to [iface: default, target: iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1, portal: 172.28.128.101,3260] successful.
```

Check the block device

```
ubuntu@client-01:~$ sudo iscsiadm -m session -P 3
iSCSI Transport Class version 2.0-870
version 2.0-873
Target: iqn.2016-09.com.openebs.jiva:demo1-vsm1-vol1 (non-flash)


		************************
		Attached SCSI devices:
		************************
		Host Number: 3	State: running
		scsi3 Channel 00 Id 0 Lun: 1
			Attached scsi disk sdc		State: running
ubuntu@client-01:~$ 

```

Check the size
```
ubuntu@client-01:~$ sudo blockdev --report /dev/sdc
RO    RA   SSZ   BSZ   StartSec            Size   Device
rw   256   512  4096          0     10737418240   /dev/sdc
ubuntu@client-01:~$ 

```

