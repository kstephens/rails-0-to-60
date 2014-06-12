if ! [ -d $app_name ]
then
  comment Create $app_name app.
  notes <<EOF
"rails new" creates a new Rails project directory.
"$rails_new_options" configures the Rails project to use PostgreSQL with ActiveRecord.

This new project directory contains: 

Gemfile        -- List gems and their versions as required by this project/
Rakefile       -- Top-level "rake" control file.
README.rdoc    -- Default README.
app/           -- 
  assets/         -- Static assets: images, *.js, *.css, etc.
  controllers/    -- Controllers define how this website interacts.
  helpers/        -- Support code for controllers and views.
  mailers/        -- E-Mail support code.
  models/         -- Define data structures stored in a database.
  views/          -- Templates to render HTML for browser.
config/        -- Various configuration files.
config.ru      -- Web server (Rack) configuration.
db/            -- Database support: schema definitions/migrations.
doc/
lib/           -- Additional support code.
log/           -- Runtime log files.
public/        -- Other static assets.
script/        -- Other development scripts.
test/          -- Test scripts.
tmp/           -- Temporary files.
vendor/        -- Locally installed gems and libraries.

EOF
  all "rails new $app_name $rails_new_options"
fi

notes <<EOF
EOF
all  "cd $app_name"

comment Bundler.
notes <<EOF
Rails uses the "bundler" gem.
The bundler uses the Gemfile to correctly select the required gem versions.

The "bundle" command:

  "bundle exec foo" runs the "foo" command using the gems listed in the Gemfile.

"bundle" is used so often during Rails development,
  define a few Bash aliases reduce the typing.
EOF
ok  "alias b='bundle'"
ok  "alias be='bundle exec'"
alias b='bundle'
alias be='bundle exec'

comment "Add libv8 therubyracer to Gemfile"
notes <<EOF
Rails needs a JavaScript interpreter; use Google's V8 engine.
EOF
if ! egrep -sq -e "^gem 'libv8'" Gemfile
then
  all "cat <<EOF >> Gemfile
gem 'libv8'
gem 'therubyracer'
EOF"
fi

comment "Other gems."
notes <<EOF
  * Newer version of webrick doesn't generate so many warnings.
  * Disable asset logging.
EOF
if ! egrep -sq -e "^gem 'webrick'" Gemfile
then
  all "cat <<EOF >> Gemfile
gem 'webrick', '~> 1.3.0'
gem 'disable_assets_logger', :group => :development
EOF"
fi

comment bundle install
notes <<EOF
"bundle install" installs all gems in the Gemfile.

It maintains a list of dependencies in the Gemfile.lock.
EOF
all bundle install
