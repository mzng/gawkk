class AddServiceUsernamesToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :twitter_username, :string
    add_column :users, :friendfeed_username, :string
  end

  def self.down
    remove_column :users, :friendfeed_username
    remove_column :users, :twitter_username
  end
end
