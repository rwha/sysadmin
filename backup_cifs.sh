#!/bin/bash
#
#  backup to cifs
#

log="/var/log/backup.log"
EMAIL="xxx@xxx.xxx"  # ticketing system
CIFS_IP="1.1.1.1"
CIFS_U="username"
CIFS_P="password"
host=$(hostname)

echo "------------------------------------------------------------------" >> $log
date >> $log
startt=$(date +%l%M)


function fail {
    echo -n "FAILURE "$(date) >> $log
    echo ": $1" >> $log
    echo "$1"$'\n'"check $log" | mail -s "$SVC backup failed" "$EMAIL"
    exit 1
}

function warning {
    tail $log | mail -s "$SVC backup warnings" "$EMAIL"
}

[ ! -d /mnt/files ] && {
    mkdir /mnt/files || fail "could not create  /mnt/files directory"
}

mount | grep files > /dev/null || {
    mount -t cifs //${CIFS_IP}/x_backups /mnt/files/ -o user=${CIFS_U},password=${CIFS_P} || fail "could not mount file server"
}

rpdir="/mnt/files/$host/"

[ ! -d "$rpdir" ] &&  {
    mkdir "$rpdir" ||  fail "could not create $rpdir"
}

if [ $(ls $rpdir | wc -l) -ge "8" ]
then
    rm -rf "$rpdir$(ls -lt $rpdir | grep '^d' | tail -1 | tr " " "\n" | tail -1)" || { echo "WARN:: could not delete oldest backup" >> $log; warn=1; }
else
    echo "WARN:: only $(ls $rpdir | wc -l) backups available" >> $log
    warn=1;
fi

buf=$(date +%Y%m%d)
[ -d $rpdir$buf ] && {
  buf=$buf"00";
  while [ -d $rpdir$buf ]
    do
        ((buf++));
    done
  rdir="$rpdir$buf";
 } || rdir="$rpdir$buf";

mkdir $rdir || fail "could not create $rdir folder"


##
#do the backup
#####


## check for db dump after piped to compress 
#dump=${PIPESTATUS[0]}
#[ ${dump} -ne "0" ] && fail "mysqldump error $dump"

## backup crontab
#crontab -l > /tmp/crontab.txt

## backup apache
#tar czpf $rdir/rt-dir-httpd-dir-backup.tar.gz /etc/httpd /var/www/html /tmp/crontab.txt > /dev/null 2>&1

## metrics
#size=$(du $rdir|cut -f1)
mysql -u xxxxx -pyyyyy -h 1.1.1.1 data_growth -e "INSERT into data (host, service, date, size_k) VALUES ('$host', 'zzzz', '$buf', '$size');"

endt=$(date +%l%M)
let "ttc=$endt-$startt"
echo "$ttc minutes to complete."$'\n' >> $log

[ $warn ] && warning;

exit 0
