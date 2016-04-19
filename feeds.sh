#!/bin/bash
log="/var/log/feeds.log"
echo "------------------------------------------------------------------" >> $log
date >> $log
startt=$(date +%l%M)

function failure {
        email="xxx@xxx.xxx"
        subject="$1"
        [ -a /var/feed_msg.txt ] && mail -s "$subject" "$email" < /var/feed_msg.txt || mail -s "$subject" "$email" < $(tail /var/log/feeds.log)
}

function feedjob {
        f=$(basename "$1"| cut -d "." -f 1)
        if [[ "${1:0:1}" == "/" ]]; then
                [ -x "$1" ] && {
                echo $'\n'"--START $f (php)" >> $log;
                /usr/bin/php -f $1 >> $log 2> /var/log/$f.stderr.log || failure "$f"; } || failure "$f feed failed"
                echo $'\n'"--END $f (php)" >> $log;
        elif [[ "${1:0:1}" == "h" ]]; then
                echo $'\n'"--START $f (curl)" >> $log;
                /usr/bin/curl "$1" >> $log 2> /var/log/$f.stderr.log || failure "$f feed failed"
                echo $'\n'"--END $f (curl)" >> $log;
        fi
        echo >> $log
}

while read -r j; do
        [[ "$j" != "exit" ]] && feedjob $j
done < /var/local/feeds.txt

endt=$(date +%l%M)
let "ttc=$endt-$startt"
echo "$ttc minutes to complete." >> $log
[ "$ttc" = "0" ] && failure "time to complete too low please check log"
exit 0

