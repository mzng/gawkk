class AddTweetLikesToTwitterAccounts < ActiveRecord::Migration
  def self.up
    add_column :twitter_accounts, :tweet_likes, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :twitter_accounts, :tweet_likes
  end
end
