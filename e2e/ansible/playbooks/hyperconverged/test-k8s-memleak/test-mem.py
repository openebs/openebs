#------------------------------------------------------------------------------
#!/usr/bin/env python
#description     :Test to verify the memory consumed with sample workloads. 
#==============================================================================

from __future__ import division
import subprocess
import time, os, sys
list = []
namespace = sys.argv[1]
cmd_cntrl_name = "kubectl get pod -n %s -l openebs/controller=jiva-controller --no-headers | awk '{print $1}'" %(namespace)
out = subprocess.Popen(cmd_cntrl_name,stdout=subprocess.PIPE,shell=True)
cntrl_name = out.communicate()
cntrl_pod_name = cntrl_name[0].strip('\n')
n = cntrl_pod_name.split('-')
lst = n[:len(n)-2]
lst.append("con")
container_name = "-".join(lst)
used_mem_process = "kubectl exec %s -c %s -n %s -- pmap -x 1 | awk ''/total'/ {print $3}'" %(cntrl_pod_name,container_name,namespace)
print used_mem_process
n = 5
count = 0
#Obtaining memory consumed by longhorn process from the cntroller pod.
while count < n:
    count = count + 1
    out = subprocess.Popen(used_mem_process,stdout=subprocess.PIPE,shell=True)
    used_mem = out.communicate()
    mem_in_mb = int(used_mem[0])/1024
    print mem_in_mb, "MB"
    if mem_in_mb < 500:
        time.sleep(20)
    else:
        print "Fail"
        #break
        quit()
    list.append(mem_in_mb)
print list
# A watermark of 500MB has been set based on benchmark runs with the workload 
# profile chosen in this test
# TODO: Identify better mem consumption strategies
if all(i <= 500 for i in list):
        print "Pass"
else:
        print "Fail"

