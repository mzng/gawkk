class AddTwitterUsernameToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :twitter_username, :string
  end

  def self.down
    remove_column :comments, :twitter_username
  end
end
