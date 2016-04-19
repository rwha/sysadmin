#!/bin/bash

CERTFILE=/home/user/.certs/gmail.pem
CERTPATH=/home/user/.certs
RCFILE=/home/user/.fetchmailrc

CCOUNT=$(wc -m $RCFILE)

## get fingerprint from current flie
OFPRINT=$(grep sslfingerprint $RCFILE | awk '{print $4}' | tail -1)
OFPRINT="${OFPRINT%\'}"
OFPRINT="${OFPRINT#\'}"

## get new certificate
echo "x" | openssl s_client -connect imap.gmail.com:993 > /tmp/cert.info 2>&1
BLINE=$(grep -n 'BEGIN CERTIFICATE' /tmp/cert.info|awk -F':' '{print $1}')
ELINE=$(grep -n 'END CERTIFICATE' /tmp/cert.info|awk -F':' '{print $1}')
sed -n ''$BLINE','$ELINE'p' /tmp/cert.info > /tmp/gmail.pem
 
## get new fingerprint and expiration info
CERTINFO=$(openssl x509 -noout -in /tmp/gmail.pem -enddate -fingerprint -md5 | awk -F'=' '{print $2}')
EDATEM=$(echo $CERTINFO | awk '{print $1}')
EDATED=$(echo $CERTINFO | awk '{print $2}')
NFPRINT=$(echo $CERTINFO | awk '{print $6}' )
 
[ $OFPRINT = $NFPRINT ] && exit 1

crontab -l |sed -e 's=\(^.*/usr/bin/fetchmail\)=#\1=' | crontab -

while [ -n "$(ps aux | egrep fetchmai[l])" ]; do
    sleep 1
done

cp $CERTFILE /root/backup/gmail.oldpem
cp $RCFILE /root/backup/rcfile

sed -i 's/'$OFPRINT'/'$NFPRINT'/g' $RCFILE || { crontab -l | sed -e 's=^#\(.*/usr/bin/fetchmail\)=\1=' | crontab -; exit 2; }

NCCOUNT=$(wc -m $RCFILE)

if [ "$NCCOUNT" = "$CCOUNT" ]; then
    mv /tmp/gmail.pem $CERTFILE
    c_rehash $CERTPATH > /dev/null 2>&1
    crontab -l | sed -e 's=^#\(.*/usr/bin/fetchmail\)=\1=' | crontab -
    exit 3
else
    mv ~/backup.rcfile $RCFILE
    echo "Updating $RCFILE failed. Manually edit this file to replace" >> /tmp/msg.txt;
    echo "$OFPRINT with $NFPRINT" >> /tmp/msg.txt
    crontab -l | sed -e 's=^#\(.*/usr/bin/fetchmail\)=\1=' | crontab -
    exit 2
fi
