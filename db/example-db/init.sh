#!/bin/bash
#
set -e

# uncomment below as needed

#psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
#    CREATE ROLE lxoffice WITH SUPERUSER;
#    CREATE ROLE postgres WITH SUPERUSER;

#    CREATE DATABASE kivitendo_auth;
#    GRANT ALL PRIVILEGES ON DATABASE kivitendo_auth TO kivitendo;
#    CREATE DATABASE mycompany1;
#    GRANT ALL PRIVILEGES ON DATABASE mycompany1 TO kivitendo;
#EOSQL
