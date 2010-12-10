# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = false
config.action_controller.perform_caching             = true

# See everything in the log (default is :info)
# config.log_level = :debug

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
#config.cache_store = :mem_cache_store, '204.188.244.130', '204.188.244.130', {:namespace => 'gawkk'}

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = false
config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = { 
   :address => "mail.gawkk.com", 
   :port => 587, 
   :domain => "gawkk.com", 
   :authentication => :login, 
   :user_name => "notifier", 
   :password => "purplemonkeydishwasher"   
}

# Enable threaded mode
# config.threadsafe!
BASE_URL = "gawkk.com"
SESSION_DOMAIN = ".gawkk.com"
BASE_URL_SIZE = 0
config.cache_store = :mem_cache_store
memcache_options = {
  :c_threshold => 10000,
  :compression => true,
  :debug => false,
  :namespace => 'a',
  :readonly => false,
  :urlencode => false

}


require 'memcache'

# make a CACHE global to use in your controllers instead of Rails.cache, this will use the new memcache-client 1.7.2
CACHE = MemCache.new memcache_options

# connect to your server that you started earlier
CACHE.servers = '127.0.0.1:11211'

# this is where you deal with passenger's forking
begin
   PhusionPassenger.on_event(:starting_worker_process) do |forked|
     if forked
       # We're in smart spawning mode, so...
       # Close duplicated memcached connections - they will open themselves
       CACHE.reset
     end
   end
# In case you're not running under Passenger (i.e. devmode with mongrel)
rescue NameError => error

end
