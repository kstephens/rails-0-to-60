#!/bin/bash

dryrun=:
prompt=1
w3m=
w3m_opts=

eval "$*"

progdir="$(cd "$(dirname "$0")" && /bin/pwd)"
source "$progdir/lib/functions.sh"

#################################

comment "Follow along in http://edgeguides.rubyonrails.org/getting_started.html"

comment "Load RVM functions."
. ~/.rvm/scripts/rvm

set -e

comment "mkdir -p ~/local/src"
all mkdir -p ~/local/src

comment "cd ~/local/src"
all cd ~/local/src

if ! [ -d blog ]
then
  comment Create blog app.
  notes <<EOF
"rails new" creates a new Rails project directory.
"-d postgresql" configures the Rails project to use PostgreSQL with ActiveRecord.

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
server.log
test/          -- Test scripts.
tmp/           -- Temporary files.
vendor/        -- Locally installed gems and libraries.

EOF
  all "rails new blog -d postgresql"
fi

ok  "cd blog"

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

comment View rake targets:
notes <<EOF
Rails provides a number of rake "tasks" for development support.

Rails requires the bundler gems.
The bundler gem uses the Gemfile to correctly select the required gem versions.
"bundle exec rake -T" runs the "rake -T" command using the Gemfile.

"bundle" is used so often a few Bash aliases reduce the typing.
EOF
all bundle exec rake -T

comment Setup bundle aliases:
ok  "alias b='bundle'"
ok  "alias be='bundle exec'"
alias b='bundle'
alias be='bundle exec'

comment Create a blog database user that can create new databases.
notes <<EOF
This creates a local PostgreSQL database user named "blog".
EOF
if PGHOST=localhost PGUSER=blog PGPASSWORD=blog psql -c 'select 1;' >/dev/null 2>&1
then
  comment Database user already exists.
else
  all "cat <<EOF | sudo -u postgres psql
CREATE ROLE blog SUPERUSER LOGIN PASSWORD 'blog';
CREATE DATABASE blog OWNER blog;
EOF"
fi
all export PGHOST=localhost PGUSER=blog PGPASSWORD=blog

comment Setup config/database.yml.
notes <<EOF
The database.yml file contains ActiveRecord configuration to connect to the DB.
EOF
all cp $progdir/database.yml config/
ok  head -20 config/database.yml

comment Create database.
all bundle exec rake db:drop:all || true

comment Create database.
all bundle exec rake db:create:all

comment "Start a the rails server."
notes <<EOF

EOF
start_server "bundle exec rails server"

comment Server Log:
ok  cat server.log

comment Browse to http://${hostname}:3000/
all browse http://${hostname}:3000/

comment Generate welcome controller.
all bundle exec rails generate controller welcome index

comment 'Add route for root to welcome#index.'
notes <<EOF
A Rails "route" tells the web server how to route URLs to the appropriate Rails Controller.
EOF
all "sed -i -e 's@^ * # root :to@  root :to@' config/routes.rb"

comment Remove public/index.html.
all "rm -f public/index.html"

comment Browse to http://${hostname}:3000/ : Default views/welcome/index.html.erb.
all "browse http://${hostname}:3000/"

comment Edit app/views/welcome/index.html.erb.
notes <<EOF

EOF
all "cat <<EOF > app/views/welcome/index.html.erb
<h1>Hello, Rails!</h1>
EOF"

comment Browse to http://${hostname}:3000/
notes <<EOF

EOF
all "browse http://${hostname}:3000/"

comment Generate posts controller.
notes <<EOF
Rails can generate many files based on standard (or optional) boilerplate.
This command generates a controller for a blog post.
EOF
all bundle exec rails g controller posts

comment Browse to http://${hostname}:3000/posts/new: Routing Error
notes <<EOF

EOF
all "browse http://${hostname}:3000/posts/new"

comment View app/controllers/posts_controller.rb
notes <<EOF

EOF
ok cat app/controllers/posts_controller.rb

comment Add route for posts/new.
notes <<EOF

EOF
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  get "posts/new"
  root :to => "welcome\\#index"
end
EOF'

comment Add new action method to controller.
notes <<EOF

EOF
all 'cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def new
  end
end
EOF'

comment Browse to http://${hostname}:3000/posts/new: Template is missing
notes <<EOF

EOF
all "browse http://${hostname}:3000/posts/new"

comment Create posts/new view template.
notes <<EOF

EOF
all 'cat <<EOF > app/views/posts/new.html.erb
<%= form_for :post do |f| %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>
 
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>
 
  <p>
    <%= f.submit %>
  </p>
<% end %>
EOF'

comment Browse to http://${hostname}:3000/posts/new: Form.
notes <<EOF

EOF
all "browse http://${hostname}:3000/posts/new"

comment Make posts/new view template post to posts#create.
notes <<EOF

EOF
all 'cat <<EOF > app/views/posts/new.html.erb
<%= form_for :post, url: { action: :create } do |f| %>
  <p>
    <%= f.label :title %><br>
    <%= f.text_field :title %>
  </p>
 
  <p>
    <%= f.label :text %><br>
    <%= f.text_area :text %>
  </p>
 
  <p>
    <%= f.submit %>
  </p>
<% end %>
EOF'

comment Browse to http://${hostname}:3000/posts/new: Form.
all "browse http://${hostname}:3000/posts/new"

comment Add route for posts/new.
notes <<EOF

EOF
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  get "posts/new"
  post "posts" => "posts#create"
  root :to => "welcome#index"
end
EOF'

comment Render input params in posts#create.
notes <<EOF

EOF
all 'cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def new
  end
  def create
    render text: params[:post].inspect
  end
end
EOF'

comment Submit to http://${hostname}:3000/posts/new: params Hash.
notes <<EOF

EOF
all "browse http://${hostname}:3000/posts/new"

comment Create the Post model.
notes <<EOF

EOF
all bundle exec rails g model Post title:string text:text

comment See app/models/post.rb.
notes <<EOF

EOF
ok cat app/models/post.rb

comment See generated DB migration.
notes <<EOF

EOF
ok cat db/migrate/*_create_posts.rb

comment Apply DB migrations.
notes <<EOF

EOF
all bundle exec rake db:migrate

comment Saving data in the controller
notes <<EOF

EOF
all 'cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def new
  end
  def create
    @post = Post.new(params[:post])
    @post.save
    redirect_to action: :show, id: @post.id
  end
end
EOF'

comment Submit to http://${hostname}:3000/posts/new: Routing Error.
notes <<EOF

EOF
all "browse http://${hostname}:3000/posts/new"

comment Add route for posts/new.
notes <<EOF

EOF
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  get  "posts/new"
  post "posts" => "posts#create"
  get  "posts/:id" => "posts#show"
  root :to => "welcome#index"
end
EOF'

comment Showing Posts
notes <<EOF

EOF
all 'cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def new
  end
  def create
    @post = Post.new(params[:post])
    @post.save
    redirect_to action: :show, id: @post.id
  end
  def show
    @post = Post.find(params[:id])
  end
end
EOF'

comment Create posts/show template.
notes <<EOF

EOF
all 'cat <<EOF > app/views/posts/show.html.erb
<p>
  <strong>Title:</strong>
  <%= @post.title %>
</p>
 
<p>
  <strong>Text:</strong>
  <%= @post.text %>
</p>
EOF'

comment Listing all posts.

comment Add route for posts/index.
notes <<EOF

EOF
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  get  "posts/new"
  post "posts"     => "posts#create"
  get  "posts/:id" => "posts#show"
  get  "posts"     => "posts#index"
  root :to => "welcome#index"
end
EOF'

comment Add action method for posts/index.
notes <<EOF

EOF
all 'cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def new
  end
  def create
    @post = Post.new(params[:post])
    @post.save
    redirect_to action: :show, id: @post.id
  end
  def show
    @post = Post.find(params[:id])
  end
  def index
    @posts = Post.all
  end
end
EOF'

comment Create template for posts/index.
notes <<EOF

EOF
all 'cat <<EOF > app/views/posts/index.html.erb
<h1>Listing posts</h1>
 
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
  </tr>
 
  <% @posts.each do |post| %>
    <tr>
      <td><%= post.title %></td>
      <td><%= post.text %></td>
    </tr>
  <% end %>
</table>
EOF'

comment Get http://${hostname}:3000/posts: Table of Posts.
all "browse http://${hostname}:3000/posts"

comment Adding links.

comment Add link to posts on home page.
notes <<EOF

EOF
all 'cat <<EOF > app/views/welcome/index.html.erb
<h1>Hello, Rails!</h1>
<%= link_to "My Blog", controller: :posts %>
EOF'

comment Get http://${hostname}:3000: My Blog link.
notes <<EOF

EOF
all "browse http://${hostname}:3000"

comment Link to post/new.
notes <<EOF

EOF
all 'cat <<EOF > app/views/posts/index.html.erb
<h1>Listing posts</h1>

<%= link_to "New Post", action: :new %><br />
<table>
  <tr>
    <th>Title</th>
    <th>Text</th>
  </tr>
 
  <% @posts.each do |post| %>
    <tr>
      <td><%= post.title %></td>
      <td><%= post.text %></td>
    </tr>
  <% end %>
</table>
EOF'

comment Get http://${hostname}:3000/posts: New post link.
notes <<EOF

EOF
all "browse http://${hostname}:3000/posts"

comment Link from posts/:id/show to posts/.
notes <<EOF

EOF
all 'cat <<EOF > app/views/posts/show.html.erb
<p>
  <strong>Title:</strong>
  <%= @post.title %>
</p>
 
<p>
  <strong>Text:</strong>
  <%= @post.text %>
</p>

<%= link_to "Posts", action: :index %><br />
EOF'

comment "ALL DONE!"
