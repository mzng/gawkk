class AddVersionToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :version, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :videos, :version
  end
end
