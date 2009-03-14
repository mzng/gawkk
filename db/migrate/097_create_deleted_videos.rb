class CreateDeletedVideos < ActiveRecord::Migration
  def self.up
    create_table :deleted_videos do |t|
      t.string    :name
      t.text      :url
      t.text      :truveo_url
      t.timestamp :deleted_at
    end
  end

  def self.down
    drop_table :deleted_videos
  end
end
