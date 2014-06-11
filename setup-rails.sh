#!/bin/bash

dryrun=:
prompt=:

eval "$*"

progdir="$(cd "$(dirname "$0")" && /bin/pwd)"
source "$progdir/lib/functions.sh"

########################################

set -e

cd "$(dirname "$0")"

ruby_version=ruby-1.9.3
rails_version='~>3.2.0'

notes <<EOF
$0 -- Setup RVM, Ruby on Rails, PostgreSQL from scratch.

This is a interactive script that installs a Ruby on Rails development environment.

Steps:

  * Configure system package manager.
  * Install C development tools.
  * Install RVM.
  * Install $ruby_version with RVM.
  * Install PostgreSQL database.
  * Install Rails $rails_version.
EOF
show_notes
prompt "Continue" y

source lib/setup/package-manager.sh
source lib/setup/dev-tools.sh
source lib/setup/rvm.sh
source lib/setup/postgresql.sh
source lib/setup/rails.sh

comment "ALL DONE!"
set_cmd "$script_cmd_line"
notes <<EOF
Now we have a complete Ruby on Rails development environment!
EOF
show_notes

