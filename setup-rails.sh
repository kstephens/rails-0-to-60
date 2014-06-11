#!/bin/bash

dryrun=:
prompt=

eval "$*"

progdir="$(cd "$(dirname "$0")" && /bin/pwd)"
source "$progdir/functions.sh"

########################################

set -e

cd "$(dirname "$0")"

notes <<EOF
$0 -- Setup RVM, Ruby, Ruby on Rails, PostgreSQL from scratch.

This is a interactive script that installs a Ruby on Rails development environment.

EOF
show_notes
prompt "Continue" y

notes <<EOF
This demo requires a few newer system packages than maybe available by default.

These can be found from Debian backports.
EOF

debian6 comment Add squeeze-backports
debian6 ok "sudo cp sources.list.d/$debian_name-backports.list /etc/apt/sources.list.d/"
debian6 ok "sudo apt-get update"

ubuntu1204 comment Add Ubuntu 12.04 precise-backports
ubuntu1204 "sudo cp sources.list.d/$debian_name-backports.list /etc/apt/sources.list.d/"
ubuntu1204 "sudo apt-get update"

comment Install base ruby.
notes <<EOF
RVM requires a system Ruby install to build Ruby.
EOF
debian "sudo apt-get install -y ruby ruby-dev"
osx    "/usr/bin/ruby"

osx comment Check for macports.
osx 'which port'

comment Install postgres w/ dev libs.
notes <<EOF
The "blog" project will use ActiveRecord on PostgreSQL 9.1.

This installs the system packages for a PostgreSQL server and clients.
EOF
debian  "sudo apt-get install -y -t $debian_name-backports postgresql-9.1 libpq-dev"
osx     'sudo port install postgresql91'

comment Install other dev tools.
notes <<EOF
Additional packages for this demo:

  * w3m             -- Terminal-based web browser.
  * curl            -- Command-line HTTP user agent.
  * build-essential -- GCC, linker, other C development tools.
  * libreadline-dev -- Ruby will link against readline, if available.
EOF
debian 'sudo apt-get install -y w3m python-dev subversion curl build-essential libreadline-dev'
osx    'sudo port install w3m python subversion curl readline'

comment Install other ruby dependencies.
notes <<EOF
System packages that Ruby and/or RoR will need:

  * openssl     -- OpenSSL for Ruby SSL support.
  * libreadline6-dev -- Ruby prefers Readline 6.
  * zlibg-dev   -- Data compression library.
  * libyaml-dev -- YAML is used in Rails database connection configuration.
  * sqlite3     -- Default database for Rails.
  * libxml2-dev -- XML DOM library for ruby-xml, nogogiri rubygems.
  * libxslt-dev -- XSLT library for ruby-xml.
  * autoconf    -- ruby ./configure script used by RVM.
  * libc6-dev   -- basic C lib.
  * libtool     -- Dynamic library tools used by Ruby Makefile.
  * bison       -- Parser generator for Ruby parse.y.
  * libffi-dev  -- Foreign Function Interface: allows ruby to call C function from dynamic libraries.
EOF
debian 'sudo apt-get install -y build-essential openssl libreadline6 libreadline6-dev git-core zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev libxml2-dev libxslt-dev autoconf libc6-dev ncurses-dev automake libtool bison subversion pkg-config sqlite3 libgdbm-dev libffi-dev'
osx    'false TODO'

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

notes <<EOF
Set up basic $PATH, $CFLAGS variables for other libraries.
EOF
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
  notes <<EOF
This will download and install RVM.

RVM is a Ruby Version Manager.
RVM installs and manages Ruby version and Rubygems.

rbenv is another ruby version manager.
EOF
  all 'curl -L https://get.rvm.io | bash -s stable'
fi

comment Use rvm.
notes <<EOF
RVM configures your Bash shell to select versions of Ruby it controls.
"source <<file>>" loads <<file>> into the current Bash shell.
EOF
set +e
all source "$HOME/.rvm/scripts/rvm"
set -e

ruby_version=ruby-1.9.3
notes <<EOF
Install ruby version $ruby_version using RVM.
EOF
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
notes <<EOF
RVM supports Ruby version defaults.
Make the default "$ruby_version".
EOF
all "rvm alias delete default"
all "rvm alias create default $ruby_version"

comment Use $ruby_version.
notes <<EOF
Use RVM $ruby_version.
EOF
all "rvm use $ruby_version" || /bin/true

comment Do not install gem docs.
notes <<EOF
Installing gem docs takes too much time.

Disable it in ~/.gemrc.
EOF
all 'mv ~/.gemrc ~/.gemrc.save || true'
all 'cat <<EOF > ~/.gemrc
gem: --no-ri --no-rdoc
EOF'

comment Install rails.
all 'gem_check rails || gem install rails --version="~>3.2.0"'

comment Install pg gem.
notes <<EOF
The ActiveRecord PostgreSQL adapter uses the pg gem which links against libpq-dev client library.
EOF
all 'gem_check pg || gem install pg'

comment Install therubyracer gem.
notes <<EOF
Ruby on Rails requires a JavaScript interpreter for its "Asset Pipeline".
The Asset Pipeline manages CSS, SASS, CoffeeScript and other static web assets.
The libv8 gem installs Google's V8 JavaScript engine.
The therubyracer gem interfaces to libv8.
EOF
all 'gem_check libv8 || gem install libv8'
all 'gem_check therubyracer || install therubyracer'

comment Install sqlite3 gem.
notes <<EOF
Sqlite3 is the default ActiveRecord database under Rails.
Sqlite3 is also useful for testing.
The sqlite3 gem links against the libsqlite3 libraries.
EOF
debian 'sudo apt-get install -y libsqlite3-dev'
osx    'sudo port install sqlite3'
all 'gem_check sqlite3 || gem install sqlite3'

comment "ALL DONE!"
set_cmd "$script_cmd_line"
notes <<EOF
Now we have a complete Ruby on Rails development environment!
EOF
show_notes
