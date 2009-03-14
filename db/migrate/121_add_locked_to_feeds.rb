class AddLockedToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :locked, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :feeds, :locked
  end
end
