class AddUrlsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :website_url, :string
    add_column :users, :feed_url, :string
  end

  def self.down
    remove_column :users, :feed_url
    remove_column :users, :website_url
  end
end
