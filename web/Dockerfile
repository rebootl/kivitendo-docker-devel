#

FROM debian:buster


RUN apt update && apt upgrade -y && apt -y install apache2 \
  libarchive-zip-perl libclone-perl \
  libconfig-std-perl libdatetime-perl libdbd-pg-perl libdbi-perl \
  libemail-address-perl  libemail-mime-perl libfcgi-perl libjson-perl \
  liblist-moreutils-perl libnet-smtp-ssl-perl libnet-sslglue-perl \
  libparams-validate-perl libpdf-api2-perl librose-db-object-perl \
  librose-db-perl librose-object-perl libsort-naturally-perl \
  libstring-shellquote-perl libtemplate-perl libtext-csv-xs-perl \
  libtext-iconv-perl liburi-perl libxml-writer-perl libyaml-perl \
  libimage-info-perl libgd-gd2-perl libapache2-mod-fcgid \
  libfile-copy-recursive-perl libalgorithm-checkdigits-perl \
  libcrypt-pbkdf2-perl libcgi-pm-perl libtext-unidecode-perl libwww-perl \
  aqbanking-tools poppler-utils libhtml-restrict-perl \
  libdatetime-set-perl libset-infinite-perl liblist-utilsby-perl \
  libdaemon-generic-perl libfile-flock-perl libfile-slurp-perl \
  libfile-mimeinfo-perl libpbkdf2-tiny-perl libregexp-ipv6-perl \
  libdatetime-event-cron-perl libexception-class-perl
# git postgresql
# postgresql-contrib (needed?)

RUN a2enmod fcgid
RUN mkdir -p /var/lock/apache2 /var/run/apache2

RUN mkdir -p /var/www/kivitendo-erp
# ^^ needed ?
# (/var/www/kivitendo-erp mounted as bind mount)

ADD 000-kivitendo.conf /etc/apache2/sites-available/000-kivitendo.conf
RUN a2dissite 000-default
RUN a2ensite 000-kivitendo

EXPOSE 80

VOLUME ["/var/log/apache2"]

ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["apache2 -D FOREGROUND"]
