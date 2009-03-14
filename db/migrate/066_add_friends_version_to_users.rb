class AddFriendsVersionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :friends_version, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :friends_version
  end
end
