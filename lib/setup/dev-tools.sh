comment Install other tools.
notes <<EOF
Additional packages for this demo:

  * w3m             -- Terminal-based web browser.
  * curl            -- Command-line HTTP user agent.
  * git             -- git version control system.
EOF
debian 'sudo apt-get install -y w3m curl git-core python-dev subversion'
osx    'sudo port install w3m curl git python subversion'

comment Install C code tools.
notes <<EOF
System packages for compiling C code:

  * build-essential  -- GCC, linker, other C development tools.
  * autoconf         -- ruby ./configure script used by RVM.
  * libc6-dev        -- Standard C libraries,.
  * libtool          -- Dynamic library tools used by Ruby Makefile.
  * bison            -- Parser generator for Ruby parse.y grammar.
EOF
debian 'sudo apt-get install -y autoconf automake libtool pkg-config bison build-essential libc6-dev'
osx    'sudo port install autoconf automake libtool pkg-config bison'

notes <<EOF
Set up basic $PATH, $CFLAGS variables for other libraries.
EOF
export CFLAGS= LDFLAGS=
if [ -d "$HOME/local/lib" -o -d "$HOME/local/bin" ]
then
comment "Use ~/local/bin, if needed."
all 'PATH="$HOME/local/bin:$PATH"'
comment "Use ~/local/lib libraries, if needed."
all 'export CFLAGS="-I$HOME/local/include" LDFLAGS="-L$HOME/local/lib"'
fi

if [ -d /opt/local ]
then
comment "Use /opt/local/lib from MacPorts."
osx 'export CFLAGS="$CFLAGS -I/opt/local/include" LDFLAGS="$LDFLAGS -I/opt/local/lib"'
fi

