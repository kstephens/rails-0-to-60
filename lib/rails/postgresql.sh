comment Create a $app_name database user that can create new databases.
notes <<EOF
This rake task creates a local PostgreSQL database user named "$app_name".
EOF
if PGHOST=localhost PGUSER=$app_name PGPASSWORD=$app_name psql -c 'select 1;' >/dev/null 2>&1
then
  comment Database user already exists.
else
  all "cat <<EOF | sudo -u postgres psql
CREATE ROLE $app_name SUPERUSER LOGIN PASSWORD '$app_name';
CREATE DATABASE $app_name OWNER $app_name;
EOF"
fi
all export PGHOST=localhost PGUSER=$app_name PGPASSWORD=$app_name

comment Setup config/database.yml.
notes <<EOF
The database.yml file contains ActiveRecord configuration to connect to the DB.
EOF
all "sed -e 's!@app_name@!$app_name!g' $progdir/lib/rails/config/database.yml >config/database.yml"

notes "---"
view_file config/database.yml -10

comment Drop database.
notes <<EOF
Rails databases are configurable for different environments,
selected by \$RAILS_ENV.

 * development
 * test
 * production

"rake db:drop:all" will drop the development and test database.
EOF
all bundle exec rake db:drop:all || true

comment Create database.
notes <<EOF
"rake db:create:all" will create the development and test database.
EOF
all bundle exec rake db:create:all

