#!/bin/bash
#
#

docker stop kivi
docker stop dockerdevkompotoi_pgadmin_1
docker exec pgsql-kivi dropdb -U kivitendo kompotest_neu
docker exec pgsql-kivi bash -c "psql -U kivitendo < kompotest.sql"
docker start kivi
docker start dockerdevkompotoi_pgadmin_1
