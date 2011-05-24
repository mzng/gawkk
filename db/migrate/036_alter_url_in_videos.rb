class AlterUrlInVideos < ActiveRecord::Migration
  def self.up
    #execute 'ALTER TABLE videos ALTER COLUMN url TYPE text'
  end

  def self.down
    #execute 'ALTER TABLE videos ALTER COLUMN url TYPE varchar(255)'
  end
end
