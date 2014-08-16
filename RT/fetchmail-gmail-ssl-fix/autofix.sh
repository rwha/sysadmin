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
 
if [ $OFPRINT = $NFPRINT ] 
then
	echo "There is a fetchmail error not related to the SSL certificate" >> /tmp/msg.txt
	exit 1;
else
	crontab -l |sed -e 's=\(^.*/usr/bin/fetchmail\)=#\1=' | crontab -
	ST=0
	while [ $ST -lt 5 ]; do 
	 FSTATUS=$(ps auxww|grep fetchmail|wc -l)
	 if [ $FSTATUS -gt 1 ]; then sleep 5; fi
	 ((ST++));
	done
	cp $CERTFILE /tmp/gmail.oldpem
	cp $RCFILE /tmp/rcfile
	sed -i 's/'$OFPRINT'/'$NFPRINT'/g' $RCFILE || { echo "unable to edit ${RCFILE}... exiting" >> /tmp/msg.txt; STATUS=2; crontab -l | sed -e 's=^#\(.*/usr/bin/fetchmail\)=\1=' | crontab -; exit $STATUS; }
	NCCOUNT=$(wc -m $RCFILE)
	if [ "$NCCOUNT" = "$CCOUNT" ] 
	 then 
	  STATUS=3
	  mv /tmp/gmail.pem $CERTFILE
	  c_rehash $CERTPATH > /dev/null 2>&1
	 else 
	  STATUS=2
	  mv ~/backup.rcfile $RCFILE
	  echo "Updating $RCFILE failed. Manually edit this file to replace" >> /tmp/msg.txt; 
	  echo "$OFPRINT with $NFPRINT" >> /tmp/msg.txt
	fi	
	crontab -l | sed -e 's=^#\(.*/usr/bin/fetchmail\)=\1=' | crontab -
	exit $STATUS;		
fi
