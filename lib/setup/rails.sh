comment Install rails.
notes <<EOF
Ruby on Rails is packaged as a Ruby gem.
EOF
all 'gem_check rails || gem install rails --version="$rails_version"'

comment Install therubyracer gem.
notes <<EOF
Ruby on Rails requires a JavaScript interpreter for its "Asset Pipeline".
The Asset Pipeline manages CSS, SASS, CoffeeScript and other static web assets.
The libv8 gem installs Google's V8 JavaScript engine.
The therubyracer gem interfaces to libv8.
EOF
all 'gem_check libv8 || gem install libv8'
all 'gem_check therubyracer || gem install therubyracer'

comment Install Sqlite3 system libraries.
notes <<EOF
The sqlite3 gem links against libsqlite3 system libraries.
EOF
debian 'sudo apt-get install -y libsqlite3-dev'
osx    'false TODO'

comment Install sqlite3 gem.
notes <<EOF
Sqlite3 is the default ActiveRecord database under Rails.
Sqlite3 is also useful for testing.
The sqlite3 gem links against the libsqlite3 libraries.
EOF
debian 'sudo apt-get install -y libsqlite3-dev'
osx    'sudo port install sqlite3'
all 'gem_check sqlite3 || gem install sqlite3'

