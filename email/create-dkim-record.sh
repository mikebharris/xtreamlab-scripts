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
dns_server_name="debord"

if [ `ssh debord grep -L "mx1.xtreamlab.net." /var/lib/bind/$domain_name.hosts | wc -l` -eq 1 ]
then
    echo "We do not manage mail for this domain, so skipping DKIM record creation"
    exit
fi

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
    echo "> Key '${keys_folder}/default.private' already exists ... regenerating"
else
    sudo mkdir "${keys_folder}"
fi

sudo opendkim-genkey -b 2048 -d "${domain_name}" -D "${keys_folder}" -s default -v
sudo chown -R opendkim:opendkim "${keys_folder}"
echo "> Created new private key '${keys_folder}/default.private'"

sudo cp "${keys_folder}/default.txt" ./tmp
sudo chmod go+rw ./tmp 

# ensure Canonalization is set to relaxed
sed "s/k=rsa;/k=rsa; c=relaxed;/" ./tmp

# add the DMARC record to the result
echo -e "_dmarc\tIN\tTXT\t\"v=DMARC1; p=quarantine; pct=100; adkim=s; aspf=s; fo=1\"" >> ./tmp

# copy the file to the remote (DNS) server and run a script to
# add the DMARC and DKIM records to the end of the DNS hosts file
scp ./tmp $dns_server_name:
sudo rm ./tmp
ssh $dns_server_name dmarc-check-and-fix.sh ${domain_name}

