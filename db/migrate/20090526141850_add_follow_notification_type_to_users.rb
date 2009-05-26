class AddFollowNotificationTypeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :follow_notification_type, :integer, :default => 2, :null => false
  end

  def self.down
    remove_column :users, :follow_notification_type
  end
end
