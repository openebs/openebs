#!/bin/sh

#######################################################################################################################
# Script Name   : bench_runner.sh         									      		
# Description   : Run vdbench I/O using the filesystem templates on the /datadir. 
# Creation Data : 20/12/2016                                                                                          
# Modifications : None											               		
# Script Author : Karthik											      
#######################################################################################################################

# Function definition 

# Use this to update the size of the volume
#updateTemplates() {
#}


#Verify that the datadir1 used by the templates is mounted
df -h -P | grep -q datadir1
if [ `echo $?` -ne 0 ]; then echo -e "datadir1 not mounted successfully, exiting \n"
exit
else echo "datadir1 mounted successfully"
fi


# Start vdbench I/O iterating through each template file

timestamp=`date +%d%m%Y_%H%M%S`
echo -e "Running Standard Workloads\n" 
pwd
id

for i in `ls ./templates/BasicTemplates/ | cut -d "/" -f 3`
do
 echo "######## Starting workload -- $i#######"
 ./vdbench -f templates/FileTemplates/$i -o output-$i-$timestamp 	
 echo "######## Ended workload -- $i#######"
done  

