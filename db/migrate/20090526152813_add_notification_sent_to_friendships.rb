class AddNotificationSentToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :notification_sent, :boolean, :default => false, :null => false
    
    Friendship.reset_column_information
    Friendship.update_all("notification_sent = true")
  end

  def self.down
    remove_column :friendships, :notification_sent
  end
end
