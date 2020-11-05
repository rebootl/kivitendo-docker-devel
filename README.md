docker development environment for kivitendo-erp incl. postgres database.

## Kivitendo setup (default github repo.)

    $ cd web/
    $ git clone https://github.com/kivitendo/kivitendo-erp.git

The entrypoint script creates the webdav directory.
Additionally it chowns the user to www-data and sets the group to rw
on first container startup.

ToDo: re-test build/run from freshly cloned

## Database setup

### Use example/dumped data

Copy database dumps from `db/example/` to `db/docker-entrypoint-initdb.d`.

Or place own database dumps there.

Tip: To create a dump from a running container use something like:

    $ docker exec docker-dev-kivi_db /usr/bin/pg_dump \
        -U kivitendo --create kivitendo > myrealcompany.sql


## Run

Adapt ports in `docker-compose.yml` as needed.

Run:

    $ docker-compose build
    $ docker-compose up -d

or

    $ docker-compose up --build -d


## Development Notes

### Postgres Container

See pgsql-kivi.notes.md.

### Kivitendo Container

See kivi.notes.md.

