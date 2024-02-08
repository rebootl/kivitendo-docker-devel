#!/bin/bash
#
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    /* add roles if neccessary */
    /*CREATE ROLE mykiviuser WITH SUPERUSER;*/
EOSQL
