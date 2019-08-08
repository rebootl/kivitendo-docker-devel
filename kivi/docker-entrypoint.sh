#!/bin/bash
#
#


# set kivitendo rw
cd /var/www/kivitendo-erp
chown -R www-data users spool webdav
chown www-data templates

source /etc/apache2/envvars
echo "$APACHE_RUN_DIR"
exec apache2 -D FOREGROUND
