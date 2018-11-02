#!/bin/sh

########################################################
# This shell script parses the individual libiscsi test 
# logs to generate a readable result summary file called
# SUMMARY.log The script also displays the total no of 
# passed and failed tests
#
# It takes the libiscsi test log folder path as argument
########################################################

Header()
{
file=$1
testSuite=$2
printf "###############################################\n" >> $file
printf "\n" >> $file 
printf "SUITE : $testSuite\n" >> $file
printf "\n" >> $file 
}

log_location=$1
result_file=`echo $HOME/SUMMARY.log`

> $result_file

t_p_count=0
t_f_count=0

for i in `ls $log_location | grep .log` 
do
{
 suite=`echo $i | sed s/'.log'//g`
 
 Header $result_file $suite;
 
 p_c=`grep Test $log_location/$i | grep -i passed | wc -l` 
 t_p_count=`expr $t_p_count + $p_c`
 grep Test $log_location/$i  | grep -i passed | awk '{printf("%-5s %20s %10s\n", $1, $2, "PASSED")}' >> $result_file
 
 f_c=`grep Test $log_location/$i | grep -i failed | wc -l`
 t_f_count=`expr $t_f_count + $f_c`
 grep Test $log_location/$i | grep -i failed | awk '{printf("%-5s %20s %10s\n", $1, $2, "FAILED")}' >> $result_file 
}
done
 
printf "No of tests passed:%s  No of tests failed:%s" $t_p_count $t_f_count



