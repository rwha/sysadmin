#!/bin/bash

cat /var/log/fetchcron.log > /tmp/fetchcron.log

if [[ -n $(tail -100 /tmp/fetchcron.log | grep -i error) ]]
 then
	cat /tmp/fetchcron.log > /tmp/msg.txt

	/home/user/bin/autofix.sh
	FIX=$(echo $?);
	
	case $FIX in
		0)
			echo "something strange happened with the autofix..." >> /tmp/msg.txt
			email=""
			;;
		1)
			echo "There is an issue with fetchmail not related to the SSL certificate." >> /tmp/msg.txt
			email=""
			;;
		2)
			echo "There is an issue with fetchmail related to the SSL certificate but the auto fix failed" >> /tmp/msg.txt
			email=""
			;;
		3)
			EXPDATE=$(/root/bin/sslexp.sh)
			echo "There was an SSL issue with fetchmail but it has been fixed. The new certificate expires ${EXPDATE}." >> /tmp/msg.txt
			email=""
			;;
		*)
			echo "something strange happened with the autofix..." >> /tmp/msg.txt
			email=""
			;;
	esac

	subject="fetchmail for RT has failed"
	mail -s "$subject" "$email" < /tmp/msg.txt
fi
