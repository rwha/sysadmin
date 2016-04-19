#!/bin/bash

iostat=`which iostat 2>/dev/null`
bc=`which bc 2>/dev/null`

function help {
echo -e "\n\tThis plugin shows the I/O usage of the specified disk, using the iostat external program.\n\tIt prints three statistics: Transactions per second (tps), Kilobytes per second\n\tread from the disk (KB_read/s) and and written to the disk (KB_written/s)\n\n$0:\n\t-d <disk>\t\tDevice to be checked (without the full path, eg. sda)\n\t-c <tps>,<read>,<wrtn>,<await>\tSets the CRITICAL level for tps, KB_read/s, KB_written/s and average wait, respectively\n\t-w <tps>,<read>,<wrtn>,<await>\tSets the WARNING level for tps, KB_read/s,  KB_written/s and average wait, respectively\n"
        exit -1
}

# Ensure needed tools are installed:
( [ ! -f $iostat ] || [ ! -f $bc ] ) && \
        ( echo "ERROR: You must have iostat and bc installed in order to run this plugin" && exit -1 )

# Get parameters:
while getopts "d:w:c:h" OPT; do
        case $OPT in
                "d") disk=$OPTARG;;
                "w") warning=$OPTARG;;
                "c") critical=$OPTARG;;
                "h") help;;
        esac
done

# Adjust three warn and crit levels:
crit_tps=`echo $critical | cut -d, -f1`
crit_read=`echo $critical | cut -d, -f2`
crit_written=`echo $critical | cut -d, -f3`
crit_await=`echo $critical | cut -d, -f4`
warn_tps=`echo $warning | cut -d, -f1`
warn_read=`echo $warning | cut -d, -f2`
warn_written=`echo $warning | cut -d, -f3`
warn_await=`echo $warning | cut -d, -f4`

# Check parameters:
[ ! -b "/dev/$disk" ] && echo "ERROR: Device incorrectly specified" && help

( [ "$warn_tps" == "" ] || [ "$warn_read" == "" ] || [ "$warn_written" == "" ] || [ "$warn_await" == "" ] ||\
  [ "$crit_tps" == "" ] || [ "$crit_read" == "" ] || [ "$crit_written" == "" ] || [ "$crit_await" == "" ] ) &&
        echo "ERROR: You must specify all warning and critical levels" && help

( [[ "$warn_tps" -ge  "$crit_tps" ]] || \
  [[ "$warn_read" -ge  "$crit_read" ]] || \
  [[ "$warn_written" -ge  "$crit_written" ]] || \
  [[ "$warn_await" -ge  "$crit_await" ]]  ) && \
  echo "ERROR: critical levels must be highter than warning levels" && help


# Doing the actual check:
iostat_read=`$iostat $disk -k -x 2 2 | grep $disk |tail -n1`
tps=`$iostat $disk -k -x 2 2 | grep $disk | tail -n1|awk '{print $2}'`
kbread=`echo $iostat_read | awk '{print $6}'`
kbwritten=`echo $iostat_read | awk '{print $7}'`
await=`echo $iostat_read | awk '{print $10}'`

# Comparing the result and setting the correct level:
if ( [ "`echo "$tps >= $crit_tps" | bc`" == "1" ] || [ "`echo "$kbread >= $crit_read" | bc`" == "1" ] || \
     [ "`echo "$kbwritten >= $crit_written" | bc`" == "1" ] || [ "`echo "$await >= $crit_await" | bc`" == "1" ]); then
        msg="CRITICAL"
        status=2
else if ( [ "`echo "$tps >= $warn_tps" | bc`" == "1" ] || [ "`echo "$kbread >= $warn_read" | bc`" == "1" ] || \
          [ "`echo "$kbwritten >= $warn_written" | bc`" == "1" ] || [ "`echo "$await >= $warn_await" | bc`" == "1" ]); then
                msg="WARNING"
                status=1
     else
        msg="OK"
        status=0
     fi
fi

# Print results:
echo "$msg - I/O stats tps=$tps KB_read/s=$kbread KB_written/s=$kbwritten Average_wait/s=$await| 'tps'=$tps; 'KB_read/s'=$kbread; 'KB_written/s'=$kbwritten; 'await'=$await;"

# Done
exit $status
