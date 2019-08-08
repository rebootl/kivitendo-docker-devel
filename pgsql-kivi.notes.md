
## pgsql

build pgsql img.:

  $ docker build pgsql-kivi -t mypgsql

(pgsql-kivi is the dir. containing the Dockerfile)

interact. cont. (example):

  $ docker run -it mypgsql /bin/bash

run (creating container):

  $ docker run --name mypgsql-test -p 55432:5432 mypgsql

  -d runs in the background

start/stop:

  $ docker start mypgsql-test
  $ docker stop mypgsql-test

attach to running:

  $ docker exec -it mypgsql-test bash
