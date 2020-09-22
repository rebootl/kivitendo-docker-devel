#!/bin/bash
find web/kivitendo-erp/users/templates-cache/templates/webpages/ -type f |xargs sudo chmod 644
find web/kivitendo-erp/webdav/ -type f |xargs sudo chmod 644
