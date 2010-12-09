set :application, "gawkk"
set :repository,  "git@github.com:mzng/gawkk.git"
set :scm, :git

if target && target == 'production'
  set :environment, :production

  set :branch, "production"
  set :deploy_to, "/home/gawkk-app/"
  set :user, :root

  role :web, "64.120.164.149"                         
  role :app, "64.120.164.149"                        
  role :db,  "64.120.164.149", :primary => true
else
  set :environment, :staging

  set :branch, "staging"
  set :deploy_to, "/var/www/apps/#{application}"
  set :user, :root

  role :web, "85.214.99.61"                         
  role :app, "85.214.99.61"                        
  role :db,  "85.214.99.61", :primary => true
end

namespace :deploy do
   task :start do ; end
   task :stop do ; end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
end


