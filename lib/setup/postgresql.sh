comment Install postgres w/ dev libs.
notes <<EOF
The "blog" project will use ActiveRecord on PostgreSQL 9.1.

This installs the system packages for a PostgreSQL server and clients.
EOF
debian  "sudo apt-get install -y -t $debian_name-backports postgresql-9.1 libpq-dev"
osx     "sudo port install postgresql91"

comment Insure new Postgres DBs use UTF8 by default.
notes <<EOF
Rails database creation tasks will use default template database, which may not use UNICODE encoding.

These psql commands will force the default template's encoding to be UNICODE.
EOF
# http://journal.tianhao.info/2010/12/postgresql-change-default-encoding-of-new-databases-to-utf-8-optional/
set +e
all "cat <<EOF | sudo -u postgres psql
UPDATE pg_database SET datistemplate = FALSE WHERE datname = 'template1';
DROP DATABASE template1;
CREATE DATABASE template1 WITH TEMPLATE = template0 ENCODING = 'UNICODE';
UPDATE pg_database SET datistemplate = TRUE WHERE datname = 'template1';
\c template1
VACUUM FREEZE;
UPDATE pg_database SET datallowconn = FALSE WHERE datname = 'template1';
EOF
"
set -e

comment Install pg gem.
notes <<EOF
The ActiveRecord PostgreSQL adapter uses the pg gem which links against libpq-dev client library.
EOF
all 'gem_check pg || gem install pg'

