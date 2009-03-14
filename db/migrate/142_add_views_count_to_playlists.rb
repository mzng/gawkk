class AddViewsCountToPlaylists < ActiveRecord::Migration
  def self.up
    add_column :playlists, :views_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :playlists, :views_count
  end
end
