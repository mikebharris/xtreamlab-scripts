#!/bin/bash

record_2024="v=spf1 include:xtreamlab.net -all"
record_2025="v=spf1 include:_spf.xtreamlab.net ~all"

pushd /var/lib/bind
for file in *.hosts; do
    if grep -sq "${record_2025}" $file
    then
	echo "$file has latest XISL SPF record ... skipping"
    else 
	serialnum=$(grep '[0-9]\{10\}' $file)
	((newserialnum=serialnum+1))	

	if grep -isq "${record_2024}" $file
	then
	    echo "$file has older SPF record; updating to new one, increasing serial number of ${newserialnumber}  ... "
	    sed -i.old "s/${record_2024}/${record_2025}/" $file
	    sed -i.old "s/${serialnum}/\t\t\t${newserialnum}/" $file
	fi

	# I fucked it up previously
	if grep -isq "record_2025" $file
	then
	    if [ `grep -L "mx1.xtreamlab.net." $file | wc -l` -ne 0 ]
	    then
		echo "$file has a fucked up SPF record, but doesn't used XISL mail servers ... deleting record"
		sed -i.old "s/\@.*IN.*TXT.*record_2025\}//" $file
		sed -i.old "s/${serialnum}/\t\t\t${newserialnum}/" $file
	    else
		echo "$file has fucked up SPF record: fixing and increasing serial number of ${newserialnumber}  ... "
		sed -i.old "s/\@.*IN.*TXT.*record_2025\}//" $file
		echo "@	IN	TXT	$record_2025" >> $file
		sed -i.old "s/${serialnum}/\t\t\t${newserialnum}/" $file
	    fi
	else 
	    if [ `grep -L "mx1.xtreamlab.net." $file | wc -l` -ne 0 ]
	    then
		echo "$file does not use XISL mail servers ... skipping"
	    else
		echo "$file has missing SPF record ... fixing"
		echo "@	IN	TXT	$record_2025" >> $file
		sed -i.old "s/${serialnum}/\t\t\t${newserialnum}/" $file
	    fi
	fi
    fi
done
popd
