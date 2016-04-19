#!/bin/bash
# delete empty files

[ $# -eq 0 ] && { echo "provide directory path"; exit; }
[ -d $1 ] || { echo "argument must be a directory"; exit; }
echo "deleting empty files in $1..."
x=0
for file in $1/*
do
        fs=$(du $file| awk '{print $1}')
        [ $fs -eq 0 ] && { rm -f $file; ((x++)); }
done
echo "$x files deleted"
