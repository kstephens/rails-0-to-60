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
<h1>Welcome to $app_name!</h1>
EOF"
all "browse $url_base/"

