#!/bin/bash
#
# dump database for inserting into docker container (for development)
#
# when dumping use --create and --no-owner (-O) to include the correct statements
# for database creation
#
# gzip it

DBNAME="$1"

sudo -u postgres pg_dump --create -O "$DBNAME" > "${DBNAME}.sql"

gzip "${DBNAME}.sql"
