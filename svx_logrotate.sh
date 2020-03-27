#!/bin/bash
#
#  svx_logrotate.sh
#
# This should be part of the svx_install.sh script


# ===== function log_rotate

# Setup & test log rotate for svxlink

function log_rotate() {
    filename="/etc/logrotate.d/svxlink"
    # Check if file exists.
    if [  -f "$filename" ] ; then
        echo "logrotate file: $filename already configured"
        return
   else
       echo "file $filename does NOT exist, will install"
       sudo tee $filename << EOT
/var/log/svxlink.log {
	rotate 7
	daily
	missingok
	compress
	delaycompress
	notifempty
	create 640 root adm
	postrotate
		invoke-rc.d rsyslog rotate > /dev/null
	endscript
}
EOT

        sudo tee /etc/rsyslog.d/01-svxlink.conf << EOT
if $programname == 'svxlink' then /var/log/svxlink.log
if $programname == 'svxlink' then ~
EOT

   fi

    echo "restart rsyslog"
    sudo service rsyslog restart

    echo "test log rotate for svxlink, view status before ..."
    grep svxlink /var/lib/logrotate/status

    sudo logrotate -v -f $filename

    echo "test log rotate, view status after ..."
    grep svxlink /var/lib/logrotate/status
}

