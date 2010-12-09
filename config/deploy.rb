set :application, "gawkk"
set :repository,  "git@github.com:mzng/gawkk.git"
set :scm, :git
set :app_symlinks, %w{images/thumbnails images/users sitemaps}

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

namespace :app do
  namespace :symlinks do
    desc "Ensures directories for symlinking are available"
    task :setup_db, :roles => :db do
      if app_symlinks
        app_symlinks.each {|link| run "mkdir -p #{shared_path}/public/#{link}"}
      end
    end

    desc "Links public directories to shared location"
    task :update_db, :roles => :db do
      if app_symlinks
        app_symlinks.each {|link| run "ln -nfs #{shared_path}/public/#{link} #{current_path}/public/#{link}"}
      end
    end
  end
end

after 'app:symlinks:setup',  'app:symlinks:setup_db'
after 'app:symlinks:update', 'app:symlinks:update_db'

