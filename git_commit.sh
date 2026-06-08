#!/bin/bash

cd /volume3/个人资料备份/Blog

now=$(date +%Y-%m-%d)
if [ -n "git status -s" ];then
    git add .
    git commit -m  "update files on $now"
    git push
else 
echo "no changes on $now"    
fi
