docker development environment for kivitendo-erp incl. postgres database.

## Kivitendo setup (default github repo.)

  $ cd kivi/
  $ git clone https://github.com/kivitendo/kivitendo-erp.git
  $ cd kivitendo-erp/
  $ mkdir webdav

The entrypoint script chowns the user to www-data and sets the group to rw
on first container startup.

## docker-compose

  $ docker-compose build
  $ docker-compose up

(adapt names/ports as necessary)

## Postgres Container

See pgsql-kivi.notes.md.

## Kivitendo Container

See kivi.notes.md.
