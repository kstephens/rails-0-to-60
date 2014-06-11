ruby_version="${ruby_version:-ruby-1.9.3}"

comment Install base ruby.
notes <<EOF
RVM requires a system Ruby install to build Ruby.
EOF
debian "sudo apt-get install -y ruby ruby-dev"
osx    "/usr/bin/ruby -V"

comment Install other ruby dependencies.
notes <<EOF
System packages that Ruby and/or RoR will need:

  * openssl     -- OpenSSL for Ruby SSL support.
  * libreadline-dev  -- Ruby will link against readline, if available.
  * libreadline6-dev -- Ruby prefers Readline 6.
  * zlibg-dev    -- Data compression library.
  * libyaml-dev  -- YAML is used in Rails database connection configuration.
  * libxml2-dev  -- XML DOM library for ruby-xml, nogogiri rubygems.
  * libxslt-dev  -- XSLT library for ruby-xml.
  * libgdbm-dev  -- gdbm database library.
  * libffi-dev   -- Foreign Function Interface: allows ruby to call C function from dynamic libraries.
EOF
debian 'sudo apt-get install -y openssl libreadline6 libreadline6-dev zlib1g-dev libssl-dev libyaml-dev libxml2-dev libxslt-dev ncurses-dev libgdbm-dev libffi-dev'
osx    'false FIXME'

if [ -d "$HOME/.rvm" ]
then
  comment rvm already installed.
else
  comment Setup rvm.
  notes <<EOF
This will download and install RVM into ~/.rvm/.

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
RVM supports Ruby version aliases and defaults.
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

