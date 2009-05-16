class AddTwitterOauthToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :twitter_oauth, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :twitter_oauth
  end
end
