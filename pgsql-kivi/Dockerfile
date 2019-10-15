FROM postgres:11

ENV POSTGRES_USER kivitendo
ENV POSTGRES_PASSWORD mypass123

COPY /docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
