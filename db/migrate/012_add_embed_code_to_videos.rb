class AddEmbedCodeToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :embed_code, :text, :default => '', :null => false
  end

  def self.down
    remove_column :videos, :saves_count
  end
end
