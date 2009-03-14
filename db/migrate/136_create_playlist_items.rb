class CreatePlaylistItems < ActiveRecord::Migration
  def self.up
    create_table :playlist_items do |t|
      t.column :playlist_id, :integer
      t.column :position, :integer
      t.column :video_id, :integer
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :playlist_items
  end
end
