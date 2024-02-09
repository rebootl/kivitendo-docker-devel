__Warning: This is intended for development on a local machine or a dedicated development server.
Do not use it in production as is. Use at your own risk.__

This contains the necessary setup and config files to create a docker environment including apache web server
and postgres database. Additionally the environment uses adminer for database administration and contains some helper scripts.

It does not however contain kivitendo itself. Kivitendo has to be set up separatelyas follows.

## Kivitendo setup

    $ cd web/
    $ git clone https://github.com/kivitendo/kivitendo-erp.git

The entrypoint script creates the webdav directory.
Additionally it chowns the user to www-data and sets the group to rw
on first container startup.

At minimum it is required to create the `kivitendo-erp/config/kivitendo.conf` by copying it from the example.
And to adapt the database server, user and password to match to values set in `docker-compose.yml`.

For the default values from `docker-compose.yml` this looks as follows:

    [authentication/database]
    host     = db
    port     = 5432
    db       = kivitendo_auth
    user     = kivitendo
    password = mypass123

For further information refer to the kivitendo documentation: https://github.com/kivitendo/kivitendo-erp/tree/master/doc

## Database setup

The required databases can be created after start up via the Administration login.

### Use dumped data

If you want to use an existing database you can place database dumps into: `db/docker-entrypoint-initdb.d`
(before startup).

Or you can insert them into the running container using the script: `db-insert.sh`.

Tip: To create a dump from a running container use something like:

    $ docker exec docker-dev-kivi_db /usr/bin/pg_dump \
        -U kivitendo --create kivitendo > myrealcompany.sql

## Run

Adapt ports in `docker-compose.yml` as needed.

Run:

    $ docker-compose up

Web-interface: http://localhost:50110/kivitendo-erp/

Admin-Login (default): admin123
