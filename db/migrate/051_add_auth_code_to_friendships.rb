class AddAuthCodeToFriendships < ActiveRecord::Migration
  def self.up
    add_column :friendships, :auth_code, :string
  end

  def self.down
    remove_column :friendships, :auth_code
  end
end
