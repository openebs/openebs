#!/bin/bash
#
# Before running this,
#    change the vols_array to reflect the volumes to be tested
# Output of running this is 'test.sh'
#

declare -a vols_array=('/dev/sdf' '/dev/sdn:/dev/sdo:/dev/sdp:/dev/sde' '/dev/sdf:/dev/sdn:/dev/sdo:/dev/sdp:/dev/sde:/dev/sdg:/dev/sdh:/dev/sdi:/dev/sdj:/dev/sdk:/dev/sdl:/dev/sdm')
# this will run the tests with 1 volume, 4 volume, and 12 volumes

declare -a ops_array=('read' 'write')
declare -a job_array=(1 4 12 64 80)

testout="./test.all.out"
testscr="./test.sh"

dospec()
{
    op=$1
    job=$2
    vols=$3
    
    volnum=`echo ${vols} | grep -o "dev" | wc -l`
    if [[ $volnum > 0 ]]; then
        
        sz=10240
        bs=4
        jspec="${op}_v${volnum}_u${job}_kb${bs}.job"
        jout="${op}_v${volnum}_u${job}_kb${bs}.out"
        
        
        echo "
[global]
filesize=${sz}m
filename=${vols}
directory=/
#direct=1
runtime=30
randrepeat=0
end_fsync=1
group_reporting=1
ioengine=libaio
fadvise_hint=0

        " > ${jspec}
        
        x=0
        while [[ $x < $job ]];
        do
            ((x+=1))
            echo "[job$x]" >> ${jspec}
            echo "rw=${op}" >> ${jspec}
            echo "bs=${bs}k" >> ${jspec}
            echo "numjobs=1" >> ${jspec}
            echo "offset=0" >> ${jspec}
        done
        
        echo "echo \"\"     >> ${testout}"                    >> ${testscr}
        echo "echo \`date\` >> ${testout}"                    >> ${testscr}
        echo "echo \"                running ${jspec}   output ${jout}\" >> ${testout}" >> ${testscr}
        echo "echo \"\"     >> ${testout}"                    >> ${testscr}
        echo ""                                               >> ${testscr}
        echo "fio ${jspec} > ${jout}"                         >> ${testscr}
        
    fi
    
}


#
# start
#

rm -f ./*.out
rm -f ./*.job
rm -f ${testout}
rm -f ${testscr}

echo "#!/bin/bash"                                          > ${testscr}
echo ""                                                     >> ${testscr}
echo "nohup watch -n 10  \"top -b -d 10 -n 3 > ./top.out\" &" >> ${testscr}
echo "TP=\$!"                                               >> ${testscr}
echo "nohup iostat -cxdt  10 3000 > ./io.out &"             >> ${testscr}
echo "IOST=\$!"                                             >> ${testscr}
echo ""                                                     >> ${testscr}
echo "echo \"pids: \${TP}  \${IOST}  \"    >> ${testout}"   >> ${testscr}
echo "echo \"\"                            >> ${testout}"   >> ${testscr}
echo "echo \`date\` >> ${testout}"                          >> ${testscr}
chmod +x ${testscr}



v=${#vols_array[@]}
o=${#ops_array[@]}
u=${#job_array[@]}

i=0
while [[ $i < $o ]]
do
    j=0
    while [[ $j < $u ]]
    do
        k=0
        while [[ $k < $v ]]
        do
            dospec ${ops_array[$i]} ${job_array[$j]} ${vols_array[$k]}
            ((k+=1))
        done
        ((j+=1))
    done
    ((i+=1))
done


echo "" >> ${testscr}
echo "[[ -z \"\$(jobs -p)\" ]] || kill \$(jobs -p)" >> ${testscr}
echo "" >> ${testscr}
