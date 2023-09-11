#!/bin/sh
now=$(date +%Y-%m-%d)
echo $now
if [ -n "git status -s" ];then
    git add .
    git commit -m  "update files on $now"
else 
echo "no changes on $now"    
fi
