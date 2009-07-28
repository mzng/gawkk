class AddInviteFriendsNoticeDismissedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :invite_friends_notice_dismissed, :boolean, :default => false, :null => false
  end
  
  def self.down
    remove_column :users, :invite_friends_notice_dismissed
  end
end
