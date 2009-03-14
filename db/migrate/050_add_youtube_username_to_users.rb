class AddYoutubeUsernameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :youtube_username, :string, :default => '', :null => false
  end

  def self.down
    remove_column :users, :youtube_username
  end
end
