# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'open-uri'

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  
  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  config.gem "feedtools", :lib => "feed_tools"
  config.gem "hpricot",   :lib => "hpricot", :version => "0.6", :source => "http://code.whytheluckystiff.net"
  config.gem "right_aws", :lib => "right_aws"
  config.gem "rmagick",   :lib => "RMagick", :version => "~>2.8"
  config.gem "twitter4r", :lib => "twitter"
  config.gem "youtube-g", :lib => "youtube_g"

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]
  config.plugins = [:redhillonrails_core, :foreign_key_migrations, :ar_fixtures, :union, 
                    :spawn, :exception_notification, 'thinking-sphinx', 
                    :acts_as_list, :browser_detect, :country_select, :white_list]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'Eastern Time (US & Canada)'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

ExceptionNotifier.exception_recipients  = %w(errors@gawkk.com)
ExceptionNotifier.sender_address        = %("Gawkk" <notifier@gawkk.com>)
ExceptionNotifier.email_prefix          = "[Gawkk ERROR] "

WhiteListHelper.bad_tags.merge %w(div a img h1 h2 h3 h4 h5 h6 p)
WhiteListHelper.tags.delete 'div'
WhiteListHelper.tags.delete 'a'
WhiteListHelper.tags.delete 'img'
WhiteListHelper.tags.delete 'h1'
WhiteListHelper.tags.delete 'h2'
WhiteListHelper.tags.delete 'h3'
WhiteListHelper.tags.delete 'h4'
WhiteListHelper.tags.delete 'h5'
WhiteListHelper.tags.delete 'h6'
WhiteListHelper.tags.delete 'p'