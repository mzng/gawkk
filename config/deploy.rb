set :application, "gawkk"
set :repository,  "git@github.com:mzng/gawkk.git"
set :branch, "staging"

set :scm, :git

set :deploy_to, "/var/www/apps/#{application}"
set :user, :root

set :environment, :staging
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

role :web, "85.214.99.61"                          # Your HTTP server, Apache/etc
role :app, "85.214.99.61"                          # This may be the same as your `Web` server
role :db,  "85.214.99.61", :primary => true # This is where Rails migrations will run

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
end


