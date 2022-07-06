#!/bin/bash
#
# insert sql file into existing/running container
#
# when dumping use --create and --no-owner (-O) to include the correct statements
# for database creation

DBFILE="$1"
DBUSER="kivitendo"

docker cp "$DBFILE" "docker-dev-kivi_db_1:/docker-entrypoint-initdb.d/"
docker exec docker-dev-kivi_db_1 bash -c "psql -U ${DBUSER} < /docker-entrypoint-initdb.d/${DBFILE}"
