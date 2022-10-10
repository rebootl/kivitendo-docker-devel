#!/bin/bash
#

WD="web/kivitendo-erp"

sudo chown -R "$USER" "$WD/"*

sudo chown -R 33 "$WD/users" "$WD/spool" "$WD/webdav"

sudo chown 33 "$WD/templates" "$WD/users"
