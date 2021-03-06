#!/bin/bash
#
#


# set kivitendo rw on first container startup
STARTED_LOCK_FILE="/started.lock"
if [ ! -e $STARTED_LOCK_FILE ]; then
  echo "-- First container startup --"
  cd /var/www/kivitendo-erp
  mkdir webdav
  chown -R www-data users spool webdav
  chmod -R g+w users spool webdav
  chown www-data templates
  chmod g+w templates

  touch $STARTED_LOCK_FILE
else
  echo "-- Not first container startup --"
fi

source /etc/apache2/envvars
echo "$APACHE_RUN_DIR"
exec "$@"
