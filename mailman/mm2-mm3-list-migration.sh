#!/bin/bash
#
# Script to migrate a mailing list from MailMan version 2 to Mailman version 3
#
# (c) Copyleft 2025 XtreamLab Internet Services Ltd
#

if [[ $# -ne 2 ]]; then
    echo "Too few arguments, please provide names of old mailing list to migrate to new target list.  Thank you."
    exit 1
fi

sudo -H -u list mailman import21 $2@lists.xtreamlab.net /var/lib/mailman/lists/$1/config.pck
sudo -H -u www-data python3 /usr/share/mailman3-web/manage.py hyperkitty_import -l $2@lists.xtreamlab.net /var/lib/mailman/archives/private/$1.mbox/$1.mbox
sudo -H -u www-data python3 /usr/share/mailman3-web/manage.py update_index_one_list $2@lists.xtreamlab.net
