require 'railsmachine/recipes'

# This defines a deployment "recipe" that you can feed to capistrano
# (http://manuals.rubyonrails.com/read/book/17). It allows you to automate
# (among other things) the deployment of your application.

# =============================================================================
# REQUIRED VARIABLES
# =============================================================================
# You must always specify the application and repository for every recipe. The
# repository must be the URL of the repository you want this recipe to
# correspond to. The deploy_to path must be the path on each machine that will
# form the root of the application path.



# Deployment Paramenters
set :github_username, 'sergeyrgv'
set :github_repository_name, 'gawkk'


# The name of your application. Used for directory and file names associated with
# the application.
set :application, "gawkk"

# Target directory for the application on the web and app servers.
set :deploy_to, "/var/www/apps/#{application}"

# Primary domain name of your application. Used as a default for all server roles.
set :domain, "gawkk.com"

# Login user for ssh.
set :user, "deploy"
set :runner, "deploy"
set :admin_runner, "deploy"


# URL of your source repository.
set :repository, "git@github.com:mzng/#{github_repository_name}.git"

# Rails environment. Used by application setup tasks and migrate tasks.
set :rails_env, "production"

# Automatically symlink these directories from curent/public to shared/public.
set :app_symlinks, %w{images/categories images/thumbnails images/users sitemaps}

# =============================================================================
# ROLES
# =============================================================================
# You can define any number of roles, each of which contains any number of
# machines. Roles might include such things as :web, or :app, or :db, defining
# what the purpose of each machine is. You can also specify options that can
# be used to single out a specific subset of boxes in a particular role, like
# :primary => true.

# Modify these values to execute tasks on a different server.
role :web, "204.188.244.130"
role :app, "204.188.244.130"
role :db,  "204.188.244.130", :primary => true

# =============================================================================
# APACHE OPTIONS
# =============================================================================
# set :apache_server_name, domain
# set :apache_server_aliases, %w{alias1 alias2}
set :apache_default_vhost, true # force use of apache_default_vhost_config
# set :apache_default_vhost_conf, "/etc/httpd/conf/default.conf"
# set :apache_conf, "/etc/httpd/conf/apps/#{application}.conf"
# set :apache_ctl, "/etc/init.d/httpd"
# set :apache_proxy_port, 8000
# set :apache_proxy_servers, 20
# set :apache_proxy_address, "127.0.0.1"
# set :apache_ssl_enabled, false
# set :apache_ssl_ip, "127.0.0.1"
# set :apache_ssl_forward_all, false

# =============================================================================
# PASSENGER OPTIONS
# =============================================================================
set :app_server, :passenger

# =============================================================================
# MONGREL OPTIONS
# =============================================================================
# set :mongrel_servers, apache_proxy_servers
# set :mongrel_port, apache_proxy_port
# set :mongrel_address, apache_proxy_address
# set :mongrel_environment, "production"
# set :mongrel_pid_file, "/var/run/mongrel_cluster/#{application}.pid"
# set :mongrel_conf, "/etc/mongrel_cluster/#{application}.conf"
# set :mongrel_user, user
# set :mongrel_group, group

# =============================================================================
# SCM OPTIONS
# =============================================================================
set :scm, "git"

# =============================================================================
# SSH OPTIONS
# =============================================================================
# ssh_options[:keys] = %w(/path/to/my/key /path/to/another/key)
# ssh_options[:port] = 25

# =============================================================================
# CAPISTRANO OPTIONS
# =============================================================================
# default_run_options[:pty] = true
set :keep_releases, 5
set :scm_username, "#{github_username}"
set :scm_password, "deploy1234"
set :branch, "master"
set :deploy_via, :remote_cache
set :git_enable_submodules, 1

# =============================================================================
# ADDITIONAL TASKS
# =============================================================================
# namespace :deploy do
#   desc "Runs asset:packager"
#   task :after_update_code, :roles => :web do
#     run <<-EOF
#       cd #{release_path} && rake RAILS_ENV=production asset:packager:build_all
#     EOF
#   end
# end

task :move_sitemaps, :roles => :web do
  #run "cp /var/www/apps/gawkk/shared/public/sitemaps/*.xml.gz /var/www/apps/gawkk/current/public/"
end

namespace :deploy do
  desc "Runs asset:packager"
  task :after_update_code, :roles => :web do
    run <<-EOF
      cd #{release_path} && rake RAILS_ENV=production asset:packager:build_all
    EOF
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
  
  namespace :maintenance do
    task :enable, :roles => :web do
      run "mv #{shared_path}/system/.maintenance.html #{shared_path}/system/maintenance.html"
    end
    
    task :disable, :roles => :web do
      run "mv #{shared_path}/system/maintenance.html #{shared_path}/system/.maintenance.html"
    end
  end
end

namespace :memcached do
  task :start, :roles => [:web, :db] do
    sudo "/etc/init.d/memcached start"
  end
  
  task :stop, :roles => [:web, :db] do
    sudo "/etc/init.d/memcached stop"
  end
end

after 'app:symlinks:setup',  'app:symlinks:setup_db'
after 'app:symlinks:update', 'app:symlinks:update_db'
after 'deploy', 'move_sitemaps'