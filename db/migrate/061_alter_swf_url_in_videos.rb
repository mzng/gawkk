class AlterSwfUrlInVideos < ActiveRecord::Migration
  def self.up
    execute 'ALTER TABLE videos ALTER COLUMN swf_url TYPE text'
  end

  def self.down
    execute 'ALTER TABLE videos ALTER COLUMN swf_url TYPE varchar(255)'
  end
end
