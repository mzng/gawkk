class AddSubscriptionCachesToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :friends_channels_cache, :text, :default => ''
    add_column :users, :subscribed_channels_cache, :text, :default => ''
    
    User.reset_column_information
    User.find(:all, :conditions => 'feed_owner = false').each do |user|
      user.reset_subscription_caches!
      say "#{user.slug}: [#{user.friends_channels_cache}] [#{user.subscribed_channels_cache}]"
    end
  end

  def self.down
    remove_column :users, :subscribed_channels_cache
    remove_column :users, :friends_channels_cache
  end
end
