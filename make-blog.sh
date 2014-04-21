#!/bin/bash

server_pid=
stop_server() {
  if [ -n "$server_pid" ]
  then
    comment Stop rails server.
    all "kill -9 $server_pid"
  fi
  server_pid=
}

start_server() {
  comment start rails server.
  all "bundle exec rails server > server.log 2>&1&"; sleep 2
  server_pid=$last_pid
  comment Server pid is $server_pid.
  echo ""
}

trap true SIGINT
trap 'prompt=; stop_server' EXIT

dryrun=:
prompt=1
w3m=
w3m_opts=

eval "$*"

w3m="${w3m:-w3m}"
browse() {
  echo -n "${_vt_INV}${_vt_LOW}"
  echo "| $* |"
  echo "+----------------------------------------------------------------------"
  echo "|${_vt_NORM} "
  ${w3m} ${w3m_opts} -graph -o color=true -o display_link=true "$@" 2>/dev/null | sed -e "s@^@${_vt_INV}|${_vt_NORM}  @"
  echo -n "${_vt_INV}${_vt_LOW}"
  echo "-----------------------------------------------------------------------"
  echo -n "${_vt_NORM}"
}

progdir="$(cd "$(dirname "$0")" && /bin/pwd)"
source "$progdir/functions.sh"

#################################

comment "Follow along in http://edgeguides.rubyonrails.org/getting_started.html"

comment "Load RVM functions."
. ~/.rvm/scripts/rvm

set -e

comment "cd ~/local/src"
all cd ~/local/src

if ! [ -d blog ]
then
  comment Create blog app.
  all "rails new blog -d postgresql"
fi

ok  "cd blog"

comment "Add libv8 therubyracer to Gemfile"
if ! egrep -sq -e "^gem 'libv8'" Gemfile
then
  all "cat <<EOF >> Gemfile
gem 'libv8'
gem 'therubyracer'
EOF"
fi

comment View rake targets:
all bundle exec rake -T

comment Setup bundle aliases:
ok  "alias b='bundle'"
ok  "alias be='bundle exec'"
alias b='bundle'
alias be='bundle exec'

comment Create a blog database user that can create new databases.
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
all cp $progdir/database.yml config/
ok  head -20 config/database.yml

comment Create database.
all bundle exec rake db:drop:all || true

comment Create database.
all bundle exec rake db:create:all

start_server

comment Server Log:
ok  cat server.log

comment Browse to http://${hostname}:3000/
all browse http://localhost:3000/

comment Generate welcome controller.
all bundle exec rails generate controller welcome index

comment 'Add route for root to welcome#index.'
all "sed -i -e 's@^ * # root :to@  root :to@' config/routes.rb"

comment Remove public/index.html.
all "rm -f public/index.html"

comment Browse to http://${hostname}:3000/ : Default views/welcome/index.html.erb.
all "browse http://localhost:3000/"

comment Edit app/views/welcome/index.html.erb.
all "cat <<EOF > app/views/welcome/index.html.erb
<h1>Hello, Rails!</h1>
EOF"

comment Browse to http://${hostname}:3000/
all "browse http://localhost:3000/"

comment Generate posts controller.
all bundle exec rails g controller posts

comment Browse to http://${hostname}:3000/posts/new: Routing Error
all "browse http://localhost:3000/posts/new"

comment View app/controllers/posts_controller.rb
ok cat app/controllers/posts_controller.rb

comment Add route for posts/new.
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  get "posts/new"
  root :to => "welcome\\#index"
end
EOF'

comment Add new action method to controller.
all 'cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  def new
  end
end
EOF'

comment Browse to http://${hostname}:3000/posts/new: Template is missing
all "browse http://localhost:3000/posts/new"

comment Create posts/new view template.
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
all "browse http://localhost:3000/posts/new"

comment Make posts/new view template post to posts#create.
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
all "browse http://localhost:3000/posts/new"

comment Add route for posts/new.
all 'cat <<EOF > config/routes.rb
Blog::Application.routes.draw do
  get "welcome/index"
  get "posts/new"
  post "posts" => "posts#create"
  root :to => "welcome#index"
end
EOF'

comment Render input params in posts#create.
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
all "browse http://localhost:3000/posts/new"

comment Create the Post model.
all bundle exec rails g model Post title:string text:text

comment See app/models/post.rb.
ok cat app/models/post.rb

comment See generated DB migration.
ok cat db/migrate/*_create_posts.rb

comment Apply DB migrations.
all bundle exec rake db:migrate

comment Saving data in the controller
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
all "browse http://localhost:3000/posts/new"

comment Add route for posts/new.
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
all "browse http://localhost:3000/posts"

comment Adding links.

comment Add link to posts on home page.
all 'cat <<EOF > app/views/welcome/index.html.erb
<h1>Hello, Rails!</h1>
<%= link_to "My Blog", controller: :posts %>
EOF'

comment Get http://${hostname}:3000: My Blog link.
all "browse http://localhost:3000"

comment Link to post/new.
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
all "browse http://localhost:3000/posts"

comment Link from posts/:id/show to posts/.
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
