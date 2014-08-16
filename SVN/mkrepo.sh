#!/bin/bash

if [ -z "$1" ]
then
  echo "usage: sudo mkrepo reponame"
  exit
fi

if [ "$2" ]
then
 echo "usage: sudo mkrepo reponame."
 exit
fi

if [ -d /var/www/svn/$1 ]
then
  echo "A repository with that name ($1) already exists."
  exit
fi


svnadmin create /var/www/svn/$1
chmod -R 775 /var/www/svn/$1
chown -R apache.apache /var/www/svn/$1
echo "The $1 repository has been created."

echo "$SUDO_USER created the $1 repository on `date`." >> /var/log/mkrepo/mkrepo.log
ls -la /var/www/svn/ | grep $1 >> /var/log/mkrepo/mkrepo.log

exit

