#!/bin/bash

FE0=21.10.88

iscsiadm -m node -u
iscsiadm -m node --op=delete

for fe in {65..76};
do
	iscsiadm -m discovery -t st -p ${FE0}.${fe}
done

iscsiadm -m node -l
xx=`iscsiadm -m session -P 3 | grep "scsi disk" | awk '{print "/dev/"$4}'`
echo $xx
