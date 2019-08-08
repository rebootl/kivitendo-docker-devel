# debian postgresql image
#
FROM debian:buster
#MAINTAINER Cem Aydin <cem.aydin@gmx.ch>

ENV postgrespassword mypass123


RUN apt update && apt upgrade -y && apt -y install postgresql

# (Run the rest of the commands as the ``postgres`` user created by the ``postgres-9.3`` package when it was ``apt-get installed``)
USER postgres

# Create a PostgreSQL role named ``docker`` with ``docker`` as the password and
# then create a database `docker` owned by the ``docker`` role.
# Note: here we use ``&&\`` to run commands one after the other - the ``\``
#       allows the RUN command to span multiple lines.
 RUN    /etc/init.d/postgresql start &&\
     psql --command "CREATE USER docker WITH SUPERUSER PASSWORD 'docker';" &&\
     psql --command "CREATE USER kivitendo WITH SUPERUSER PASSWORD '${postgrespassword}';" &&\
     createdb -O docker docker &&\
     createdb -O kivitendo kivitendo

# what is the postgres user default password ? matters for prod. only ?!?!

# Adjust PostgreSQL configuration so that remote connections to the
# database are possible.
RUN echo "host all  all    0.0.0.0/0  md5" >> /etc/postgresql/11/main/pg_hba.conf
# And add ``listen_addresses``
RUN echo "listen_addresses='*'" >> /etc/postgresql/11/main/postgresql.conf

# Expose the PostgreSQL port
EXPOSE 5432

# Add VOLUMEs to allow backup of config, logs and databases
VOLUME  ["/etc/postgresql", "/var/log/postgresql", "/var/lib/postgresql"]

# Set the default command to run when starting the container
CMD ["/usr/lib/postgresql/11/bin/postgres", "-D", "/var/lib/postgresql/11/main", "-c", "config_file=/etc/postgresql/11/main/postgresql.conf"]
