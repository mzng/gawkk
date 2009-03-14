class AddKeepFreshToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :keep_fresh, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :feeds, :keep_fresh
  end
end
