class AddNextVideosToSaves < ActiveRecord::Migration
  def self.up
    add_column :saves, :next_videos, :text, :default => ''
  end

  def self.down
    remove_column :saves, :next_videos
  end
end
