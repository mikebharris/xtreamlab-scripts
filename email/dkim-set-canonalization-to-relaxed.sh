#!/bin/bash

pushd /var/lib/bind
for file in *.hosts; do
    if grep -sq "c=relaxed;" $file
    then
	echo "$file has DKIM canonalization set to relaxed already ... skipping"
    else 
	serialnum=$(grep '[0-9]\{10\}' $file)
	((newserialnum=serialnum+1))	
	sed -i.old -e "s/${serialnum}/\t\t\t${newserialnum}/" -e 's/k=rsa;/k=rsa; c=relaxed;/' $file
    fi
done
popd
