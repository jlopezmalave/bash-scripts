#
# Script Name: downloader.sh
# Description: The script downloads all .nessus files from Tenable SecurityCenter completed within 12 hours.
# Author: Jose Lopez
#

#!/bin/bash

curl -s -k -X POST -d '{"username":"","password":""}' -c sc_cookie.txt https://<endpoint url>/rest/token > your-file.txt # Enter your IP address or endpoint URL; Also enter the name of the text file to save cookies to

key=$(grep -Eo '[0-9]+' your-file.txt | sed -n 12p) && echo $key

curl -s -k GET -H "X-SecurityCenter: ${key}" -b sc_cookie.txt https://<endpoint url>/rest/scanResult?fields=name,startTime,finishTime | python -m json.tool > your-file.txt

MY_ARRAY=$(cat time.txt | grep "finishTime" | cut -d '"' -f 4)

for i in $MY_ARRAY;
do
 myvar=$(date -d @"$i")
 if [[ $i -ge  $(date -d '12 hours ago' +%s) ]];
 then
  echo $myvar

  ID=$(grep $i time.txt -A 4 | grep "id" | cut -d '"' -f 4) && echo $ID

  curl -s -k -X POST -d '{"username":"<account name>","password":"<password>"}' -c sc_cookie.txt https://<endpoint url>/rest/token > your-file.txt

  key=$(grep -Eo '[0-9]+' scauto.txt | sed -n 12p) && echo $key

  curl -s -k -X POST -H "X-SecurityCenter: ${key}" -b sc_cookie.txt https://<endpoint url>/rest/scanResult/${ID}/download > ${ID}.zip

 fi
done
