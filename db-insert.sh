#!/bin/bash
#
# insert sql file into existing/running container
#
# when dumping use --create and --no-owner (-O) to include the correct statements
# for database creation

DB="$1"
DBUSER="kivitendo"

docker cp "$DB".sql "docker-dev-kivi-kompo-db-1:/docker-entrypoint-initdb.d/"
docker restart docker-dev-kivi-kompo-db-1
sleep 5
docker exec docker-dev-kivi-kompo-db-1 bash -c "dropdb -U ${DBUSER} --if-exists ${DB}"
docker exec docker-dev-kivi-kompo-db-1 bash -c "psql -U ${DBUSER} < /docker-entrypoint-initdb.d/${DB}.sql"
