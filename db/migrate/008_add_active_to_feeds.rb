class AddActiveToFeeds < ActiveRecord::Migration
  def self.up
    add_column :feeds, :active, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :feeds, :active
  end
end
