from __future__ import division
import subprocess
import time, os

cmd_total_mem = "sudo free | awk ' /'Mem'/ {print $2}'"

out = subprocess.Popen(cmd_total_mem,stdout=subprocess.PIPE, shell=True)
total_mem = out.communicate()
list = []
n = 10
count = 0
while count < n:
    count = count + 1
    cmd_used_mem = "sudo free | awk ' /'Mem'/ {print $3}'"
    out = subprocess.Popen(cmd_used_mem,stdout=subprocess.PIPE, shell=True)
    used_mem = out.communicate()
    mem_in_mb = int(used_mem[0])/1024
    time.sleep(20)
    list.append(mem_in_mb)
print list
if all(i <= 500 for i in list):
        print "Pass"
else:
        print "Fail"


