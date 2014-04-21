#!/bin/bash

dryrun=:
prompt=

eval "$*"

progdir="$(cd "$(dirname "$0")" && /bin/pwd)"
source "$progdir/functions.sh"

########################################

set -e

cd "$(dirname "$0")"

debian6 comment Add squeeze-backports
debian6 "sudo cp squeeze-backports.list /etc/apt/sources.list.d/"
debian6 "sudo apt-get update"

comment Install base ruby.
debian "sudo apt-get install -y ruby ruby-dev"
osx    "/usr/bin/ruby"

osx comment Check for macports.
osx 'which port'

comment Install postgres w/ dev libs.
debian6 'sudo apt-get install -y -t squeeze-backports postgresql-9.1 libpq-dev'
osx     'sudo port install postgresql91'

comment Install other dev tools.
debian 'sudo apt-get install -y w3m python-dev subversion curl build-essential libreadline-dev'
osx    'sudo port install w3m python subversion readline'

comment Install other ruby dependencies.
debian 'sudo apt-get install -y build-essential openssl libreadline6 libreadline6-dev git-core zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config sqlite3 libgdbm-dev libffi-dev'
osx    'false TODO'

comment Insure new postgres DBs use UTF8 by default.
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

comment "Use ~/local/bin, if needed."
all 'PATH="$HOME/local/bin:$PATH"'
comment "Use ~/local/lib libraries, if needed."
all 'export CFLAGS="-I$HOME/local/include" LDFLAGS="-L$HOME/local/lib"'
if [ -d /opt/local ]
then
comment "Use /opt/local/lib from MacPorts."
osx 'export CFLAGS="$CFLAGS -I/opt/local/include" LDFLAGS="$LDFLAGS -I/opt/local/lib"'
fi

if [ -d "$HOME/.rvm" ]
then
  comment rvm already installed.
else
  comment Setup rvm.
  all 'curl -L https://get.rvm.io | bash -s stable'
fi

comment Use rvm.
set +e
all source "$HOME/.rvm/scripts/rvm"
set -e

ruby_version=ruby-1.9.3
case "$(rvm list strings)"
in
  *${ruby_version}*)
    comment rvm $ruby_version already installed.
  ;;
  *)
    comment rvm install $ruby_version
    osx 'sudo port install libyaml'
    all "rvm install $ruby_version" || true
  ;;
esac

comment Set default to $ruby_version.
all "rvm alias delete default"
all "rvm alias create default $ruby_version"

comment Use $ruby_version.
all "rvm use $ruby_version" || /bin/true

comment Do not install gem docs.
all 'mv ~/.gemrc ~/.gemrc.save || true'
all 'cat <<EOF > ~/.gemrc
gem: --no-ri --no-rdoc
EOF'

comment Install rails.
all 'gem which rails >/dev/null 2>&1 || gem install rails --version="~>3.2.0"'

comment Install pg gem.
all 'gem which pg >/dev/null 2>&1 || gem install pg'

comment Install therubyracer gem.
all 'gem install libv8'
all 'gem install therubyracer'

comment Install sqlite3 gem.
debian 'sudo apt-get install -y libsqlite3-dev'
osx    'sudo port install sqlite3'
all 'gem which sqlite3 >/dev/null 2>&1 || gem install sqlite3'

comment "ALL DONE!"
