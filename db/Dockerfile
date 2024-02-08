FROM postgres:16.1

RUN localedef -i de_CH -c -f UTF-8 -A /usr/share/locale/locale.alias de_CH.UTF-8
ENV LANG de_CH.utf8

COPY /docker-entrypoint-initdb.d/* /docker-entrypoint-initdb.d/
