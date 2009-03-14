class AddPublicAndLastSaveAtToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :user_owned, :boolean, :default => true
    add_column :channels, :last_save_at, :timestamp
    Channel.reset_column_information
    
    Channel.find(:all, :include => :user).each do |channel|
      channel.user_owned = !channel.user.feed_owner?
      last_save = channel.saves.find(:first, :order => 'saves.created_at DESC')
      channel.last_save_at = last_save.created_at if last_save
      channel.save
    end
  end

  def self.down
    remove_column :channels, :last_save_at
    remove_column :channels, :user_owned
  end
end
