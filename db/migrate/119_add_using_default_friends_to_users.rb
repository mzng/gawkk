class AddUsingDefaultFriendsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :using_default_friends, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :using_default_friends
  end
end
