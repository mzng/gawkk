class CreatePlaylists < ActiveRecord::Migration
  def self.up
    create_table :playlists do |t|
      t.column :user_id, :integer
      t.column :channel_id, :integer
      t.column :name, :string
      t.column :slug, :string
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :playlists
  end
end
