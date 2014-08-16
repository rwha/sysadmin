#!/bin/bash
path=$(pwd)

if [ "$1" == "update" ]
then
 svnserve -d -r /var/www/svn --config-file=/root/temp/.svnserve.conf
 svnproc=`ps x|grep svnserve |grep -v grep |awk '{print $1}'`
 cd /root/temp
 echo "updating the repo index.  This may take a few minutes."
 echo "to cancel press ctrl+c at any time then run: 'sudo kill $svnproc'." 
 echo " "
   for i in *
   do
     svn up --ignore-externals $i >> /var/log/searchrepo.log 2>>/var/log/searchrepo.log
   done
 kill $svnproc
 echo "index update complete." 
 exit 0
fi


if [ -z "$1" ]
then
  echo "usage: sudo searchrepo reponame searchterm"
  echo "       use all for reponame to search all repos."
  echo "  "
  echo "       searching all repos can take a lot of time"
  echo "       and you could end up with a massive file that might not help..."
  echo "  "
  echo "       you can update the search index with:"
  echo "       sudo searchrepo update"
  echo "  "
  echo "       see available repos with:"
  echo "       sudo searchrepo list"
  exit 0
fi

if [ -z "$2" ]
then
   if [ "$1" == "list" ]
     then
       ls /root/temp/
       exit 0
   else
     echo "please specify the search term."
     exit 0
   fi
fi

case_repo=(`ls -l /var/www/svn | grep '^d'|awk '{print $9}'`);
case_index=(`ls -l /root/temp | grep '^d'|awk '{print $9}'`);
if [ ${#case_repo[@]} -eq ${#case_index[@]} ] 
then 
	typed_case=$1
	typed_lower=${typed_case,,}
	lc_repo=(`ls -l /var/www/svn | grep '^d'|awk '{print $9}'|tr '[:upper:]' '[:lower:]'`);
	lc_index=(`ls -l /root/temp | grep '^d'|awk '{print $9}'|tr '[:upper:]' '[:lower:]'`);
	rcount=${#lc_repo[@]}
	icount=${#lc_index[@]}
	for (( i = 0; i < ${#lc_repo[@]}; i++ )); do
	   if [ "${lc_repo[$i]}" = "$typed_lower" ]; then
	       fixed_case=${case_repo[$i]};
	   fi
	done
fi

if [[ -z "$fixed_case" ]]
then
	echo "New repos exist; please run 'sudo searchrepo update' and try again."
	exit 0;
fi

repopath="/var/www/svn/$fixed_case"
indexpath="/root/temp/$fixed_case"
date=$(date +%s)
log="$path/$date"
log="$log.txt"

if [ -d "$repopath" -a ! -d "$indexpath" ]
then
 echo "repo exists but has not been indexed. please run 'sudo searchrepo update'."
 exit 0
fi

if [ "$1" == "all" ]
then
 repo="/root/temp/"
 echo "searching all the repos for $2.  this might take a few minutes."
 echo "press ctrl+c to cancel at any time and browse $log for results."
else
   if [ ! -d "$repopath" ] 
     then
       echo "$1 repository does not exist."
       exit 0
   fi
   repo="$fixed_case"
fi


cd /root/temp
grep -H -r -i "$2" $repo > $log
if [ -s $log ]
 then
  echo "results in $log."
 else
  echo "no results found."
  rm $log
fi
