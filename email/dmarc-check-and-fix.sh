#!/bin/bash
#
# Add a DMARC and DKIM record (in the file 'tmp')
# to the end of a copy of the hosts file
# unless they already exist or XtreamLab doesn't host email
#
# (c) Copyleft 2025 XtreamLab Internet Services Ltd
#

if [ $# -eq 0 ]
then
  echo "Usage: dmarc-check-and-fix.sh <domain-name>"
  exit 0
fi

domain_name=$1
hosts_file="${domain_name}.hosts"
file_containing_dkim_and_dmarc_records="tmp"

if grep -l "mx1.xtreamlab.net." /var/lib/bind/$hosts_file | xargs grep -L 'DMARC1'
then
    echo "$file does not use XISL mail servers or already has a DMARC record ... exiting"
    exit 0
fi

cp /var/lib/bind/$hosts_file .
serialnum=$(grep '[0-9]\{10\}' $hosts_file)
((newserialnum=serialnum+1))	

sed -i.old "s/${serialnum}/\t\t\t${newserialnum}/" $hosts_file
cat $file_containing_dkim_and_dmarc_records >> $hosts_file
