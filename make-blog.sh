#!/bin/bash

dryrun=:
prompt=1
w3m=
w3m_opts=

eval "$*"

progdir="$(cd "$(dirname "$0")" && /bin/pwd)"
source "$progdir/lib/functions.sh"
stop_server

#################################

url_port=3000
url_base="http://${hostname}:${url_port}"

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
test/          -- Test scripts.
tmp/           -- Temporary files.
vendor/        -- Locally installed gems and libraries.

EOF
  all "rails new blog -d postgresql"
fi

notes <<EOF
EOF
all  "cd blog"

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

comment Create a blog database user that can create new databases.
notes <<EOF
This rake task creates a local PostgreSQL database user named "blog".
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
all "cp $progdir/lib/blog/config/database.yml config/"

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

comment "Start a the rails server."
notes <<EOF
Rails will, by default, use the pure Ruby WEBrick web server.

There are others that can work with Rails: Apache, NGINX, Unicorn, etc. 
EOF
start_server "bundle exec rails server"

notes "---"
view_file log/server.log

comment Browse to $url_base/
notes <<EOF
By default, Rails gives you a Welcome to Rails page.
EOF
all browse $url_base/

notes <<EOF
Rails embraces the REST (Representational State Transfer) design pattern.
REST actions on data models are represented as HTML GET/POST interactions on resource representations of the data.

The RESTful URLs on a model named "Post":

  GET  /posts           - index of Posts.
  GET  /posts/new      -- new Post form to create.
  POST /posts          -- create a new Post from parameters.
  GET  /posts/ID       -- show a Post by its ID.

EOF
show_notes

comment Generate welcome controller.
notes <<EOF
Rails can generate many files based on standard (or optional) boilerplate.

Generate a controller for a blog post with an "index" action.

The controller will be named WelcomeController.
It will have an action method "index".
EOF
all bundle exec rails generate controller welcome index

notes <<EOF
A Rails "route" tells the web server how to route URLs to the Controller#action.

Routes are defined in config/routes.rb.
EOF
view_file config/routes.rb

comment 'Add route for root to welcome#index.'
notes <<EOF
The "root" route directs "$url_base/" to the appropriate Controller.

Both "$url_base" and "$url_base/welcome" will be routed to WelcomeController#index.
EOF
all "cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get 'welcome/index'
  root :to => 'welcome#index'
end
EOF"

comment Remove public/index.html.
notes <<EOF
Rails has a standard public/index.html "Welcome aboard".

It must be removed to render the root route.
EOF
all "rm -f public/index.html"

comment Browse to $url_base/ : Default views/welcome/index.html.erb.
notes <<EOF
Renders app/views/welcome/index.html.erb ERB template.
EOF
all "browse $url_base/"

notes "---"
view_file app/views/welcome/index.html.erb

comment Edit app/views/welcome/index.html.erb.
notes <<EOF
Change the generate to some static HTML.
EOF
all "cat <<EOF > app/views/welcome/index.html.erb
<h1>Welcome to my blog!</h1>
EOF"

comment Browse to $url_base/
notes <<EOF

EOF
all "browse $url_base/"

comment Generate posts controller.
notes <<EOF
Generates a controller for a blog post.
EOF
all bundle exec rails g controller posts

comment Browse to $url_base/posts/new: Routing Error
notes <<EOF
Renders a Routing Error because route to PostsController#new does not exist.
EOF
all "browse $url_base/posts/new"

view_file app/controllers/posts_controller.rb

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

comment Browse to $url_base/posts/new: Template is missing
notes <<EOF

If a Controller#action method does not call "render :TEMPLATE_NAME",
it will automatically "render :ACTION'.

PostsController#new will attempt to render a app/views/posts/new.* template.

EOF
all "browse $url_base/posts/new"

comment Create posts/new view template.
notes <<EOF
Use ERB template language for views.

  "<%= {{RUBY}} %>"    -- Evaluate ruby and output the result.
  "<%  {{RUBY}} %>"    -- Evaluate ruby without the output.

  "form_for" is a Rails view helper that generates HTML <form> blocks and <input> elements.

There are other template languages than can be used with Rails: e.g. HAML, Mustache.

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

comment Browse to $url_base/posts/new: Form.
notes <<EOF

EOF
all "browse $url_base/posts/new"

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

comment Browse to $url_base/posts/new: Form.
all "browse $url_base/posts/new"

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
Render the POST params as text/plain data.
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
all "browse $url_base/posts/new"
all POST $url_base/posts "'post[title]=rails-0-to-60 is AWESOME!'" "'post[text]=https://github.com/kstephens/rails-0-to-60'" 

comment Create the Post model.
notes <<EOF
The posts/create action does not store anything yet.

Create an ActiveRecord Model class to be stored in the DB.
EOF
all bundle exec rails g model Post title:string text:text

comment See app/models/post.rb.
notes <<EOF

EOF
ok cat app/models/post.rb

comment See generated DB migration.
notes <<EOF
"t.timestamps" adds created_at and updated_at timestamp columns.

The created_at/updated_at timestamps are automatically set by ActiveRecord.

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

comment Submit to $url_base/posts/new: Routing Error.
notes <<EOF

EOF
all "browse $url_base/posts/new"

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
The "show" action method loads a post by its :id column.
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
cat <<COMMENT >/dev/null
comment Use RESTful resource routes for posts.
notes <<EOF
Rails RESTful routes use the "resource" shorthand.
EOF
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  resource :posts
  root :to => "welcome#index"
end
EOF'
COMMENT
all 'bundle exec rake routes'

comment Add action method for posts/index.
notes <<EOF
The "index" action uses ActiveRecord to load all Posts from the DB.
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
Generate a table of all Posts.
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

comment Get $url_base/posts: Table of Posts.
all "browse $url_base/posts"

comment Adding links.

comment Add link to posts on home page.
notes <<EOF

EOF
all 'cat <<EOF >> app/views/welcome/index.html.erb
<%= link_to "Posts", controller: :posts %>
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

comment Get $url_base/posts: New post link.
notes <<EOF
Now it generates new Post form.
EOF
all "browse $url_base/posts"

comment Submit New Post
notes <<EOF
/posts/create redirects to /posts/:id.
EOF
all POST $url_base/posts "'post[title]=rails-0-to-60 is AWESOME!'" "'post[text]=https://github.com/kstephens/rails-0-to-60'" 

comment Link from posts/:id to posts/.
notes <<EOF
Add a navigation link back to index action.
Show the Post#created_at.
EOF
all 'cat <<EOF > app/views/posts/show.html.erb
<p>
  <strong>Title:</strong>
  <%= @post.title %>
</p>

<p>
  <strong>Created At:</strong>
  <%= @post.created_at.iso8601 %>
</p>
 
<p>
  <strong>Text:</strong>
  <%= @post.text %>
</p>

<%= link_to "Posts", action: :index %><br />
EOF'
all "browse $url_base/posts/1"

comment Get $url_base/posts
notes <<EOF
Lists new post.
EOF
all "browse $url_base/posts"

comment List more Post attributes.
notes <<EOF
Show Post#id and #created_at.
EOF
all 'cat <<EOF > app/views/posts/index.html.erb
<h1>Listing posts</h1>

<%= link_to "New Post", action: :new %><br />
<table>
  <tr>
    <th>ID</th>
    <th>Title</th>
    <th>Posted</th>
  </tr>
 
  <% @posts.each do |post| %>
    <tr>
      <td><%= post.id %></td>
      <td><%= post.title %></td>
      <td><%= post.created_at.iso8601 %></td>
    </tr>
  <% end %>
</table>
EOF'
all "browse $url_base/posts"

comment Submit New Post
notes <<EOF
Another Post
EOF
all POST $url_base/posts "'post[title]=Second Post'" "'post[text]=Lorum Ipsom'" 
all "browse $url_base/posts"

comment 'Navigation from /posts #index to /posts/ID #show.'
notes <<EOF
Show the Post#id.
Link to show each Post.
EOF
all 'cat <<EOF > app/views/posts/index.html.erb
<h1>Listing posts</h1>

<%= link_to "New Post", action: :new %><br />
<table>
  <tr>
    <th>ID</th>
    <th>Title</th>
    <th>Posted</th>
    <th></th>
  </tr>
 
  <% @posts.each do |post| %>
    <tr>
      <td><%= post.id %></td>
      <td><%= post.title %></td>
      <td><%= post.created_at.iso8601 %></td>
      <td><%= link_to "Show", action: :show, id: post %></td>
    </tr>
  <% end %>
</table>
EOF'
all "browse $url_base/posts"

comment Sort posts from newest to oldest.
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
    @posts = Post.scoped.order("created_at desc")
  end
end
EOF'
all "browse $url_base/posts"

comment "ALL DONE!"
notes <<EOF
We are finished!
Questions?

TO DO:

  * /posts/:id/edit
     (Hint: reuse <form> from views/posts/new.html.erb in a "partial")
  * Improve navigation.
     (Hint: create a header/footer layout partials)
EOF
prompt=1
prompt "QUIT?" "q"

