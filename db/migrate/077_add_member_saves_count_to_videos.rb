class AddMemberSavesCountToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :member_saves_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :videos, :member_saves_count
  end
end
