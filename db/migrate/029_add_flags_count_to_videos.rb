class AddFlagsCountToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :flags_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :videos, :flags_count
  end
end
