class RemoveDeletedFromVideos < ActiveRecord::Migration
  def self.up
    remove_column :videos, :deleted
  end

  def self.down
    add_column :videos, :deleted, :boolean, :default => false, :null => false
  end
end
