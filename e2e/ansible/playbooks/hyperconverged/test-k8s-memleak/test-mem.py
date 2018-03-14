#------------------------------------------------------------------------------
#!/usr/bin/env python
#description     :Test to verify the memory consumed with sample workloads. 
#==============================================================================

from __future__ import division
import subprocess
import time, os
list = []
n = 10
count = 0
while count < n:
    count = count + 1
    #Obtaining memory consumed using free command from the node where the controller
    #is scheduled.
    cmd_used_mem = "sudo free | awk ' /'Mem'/ {print $3}'"
    out = subprocess.Popen(cmd_used_mem,stdout=subprocess.PIPE, shell=True)
    used_mem = out.communicate()
    mem_in_mb = int(used_mem[0])/1024
    time.sleep(20)
    list.append(mem_in_mb)
print list
# A watermark of 500MB has been set based on benchmark runs with the workload 
# profile chosen in this test
# TODO: Identify better mem consumption strategies
if all(i <= 500 for i in list):
        print "Pass"
else:
        print "Fail"


