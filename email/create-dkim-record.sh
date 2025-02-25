#!/bin/bash
#
# Script that will create a new DKIM setup for a domain and prepare the DNS update
#  (c) Copyleft 2025 XtreamLab Internet Services Ltd
#

if [ $# -eq 0 ]
then
  echo "Usage: create-dkim-record.sh <domain-name>"
  exit 0
fi

domain_name=$1

open_dkim_folder="/etc/opendkim"

signing_table_name="${open_dkim_folder}/signing.table"
signing_table_entry="*@${domain_name} default._domainkey.${domain_name}"

# Check for a entry in the signing key table and update where necessary
if grep -sq "${signing_table_entry}" $signing_table_name
then
    echo "> There is already an entry in the signing table ... skipping"
else
    echo "${signing_table_entry}" | sudo tee -a $signing_table_name
    echo "> Created the entry '${signing_table_entry}' in the table '${signing_table_name}'"
fi

key_table_name="${open_dkim_folder}/key.table"
keys_folder="${open_dkim_folder}/keys/${domain_name}"
key_table_entry="default._domainkey.${domain_name} ${domain_name}:default:${keys_folder}/default.private"

# check for an entry in the key table and update
if grep -sq "${domain_name}" $key_table_name
then
    echo "> There is already an entry in the key table ... skipping"
else
    echo "${key_table_entry}" | sudo tee -a $key_table_name
    echo "> Created the entry '${key_table_entry}' in the table '${key_table_name}'"
fi 

# create the DKIM private key
if sudo test -f ${keys_folder}/default.private
then
    echo "> Key '${keys_folder}/default.private' already exists ... skipping"
else
    sudo mkdir "${keys_folder}"
    sudo opendkim-genkey -b 2048 -d "${domain_name}" -D "${keys_folder}" -s default -v
    sudo chown opendkim:opendkim "${keys_folder}/default.private"
    echo "> Created new private key '${keys_folder}/default.private'"
fi

# add the DMARC record to the result
sudo cp "${keys_folder}/default.txt" ./tmp
echo -e "_dmarc\tIN\tTXT\t\"v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s; fo=1\"" >> ./tmp

# copy the file to the remote (DNS) server and run a script to
# add the DMARC and DKIM records to the end of the DNS hosts file
scp ./tmp debord:
ssh debord ./dmarc-check-and-fix.sh ${domain_name}

