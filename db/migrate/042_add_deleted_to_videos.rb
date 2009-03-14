class AddDeletedToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :deleted, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :videos, :deleted
  end
end
