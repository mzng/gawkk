class AddSavesCountToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :saves_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :videos, :saves_count
  end
end
