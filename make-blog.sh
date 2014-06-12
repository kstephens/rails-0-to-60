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
app_name="blog"
rails_database_adapter="postgresql"
rails_new_options="-d $rails_database_adapter"

comment "Follow along in http://edgeguides.rubyonrails.org/getting_started.html"

comment "Load RVM functions."
. ~/.rvm/scripts/rvm

#################################

set -e

comment "mkdir -p ~/local/src"
all mkdir -p ~/local/src

comment "cd ~/local/src"
all cd ~/local/src

source "$progdir/lib/rails/rails-new.sh"
source "$progdir/lib/rails/$rails_database_adapter.sh"
source "$progdir/lib/rails/welcome-controller.sh"

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
Replace:

  def index
    @posts = Post.all
  end

With:

  def index
    @posts = Post.scoped.order("created_at desc")
  end
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

