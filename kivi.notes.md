
setup from my fork:

  $ cd kivi/
  $ git clone https://github.com/rebootl/kivitendo-erp.git
  $ cd kivitendo-erp/
  $ git remote add upstream https://github.com/kivitendo/kivitendo-erp.git

(update from upstream:
 pull upstream on master: $ git pull upstream master
 push to my fork: $ git push)

(get another branch from remote, e.g.:
  $ git fetch origin perlkurs-standardkonto:perlkurs-standardkonto)


basic kivitendo setup stuff:

  $ mkdir webdav
  $ chmod 775 webdav templates users
(chown to www-data is done in entrypoint script)

build:

  $ docker build . -t mykivi

run container:

  $ docker run --name mykivi-test \
      -v ${PWD}/kivitendo-erp:/var/www/kivitendo-erp \
      -p 8080:80 mykivi

start/stop:

  $ docker start mykivi-test
  $ docker stop mykivi-test

attach to running:

  $ docker exec -it mykivi-test bash
