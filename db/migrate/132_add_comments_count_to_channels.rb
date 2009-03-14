class AddCommentsCountToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :comments_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :channels, :comments_count
  end
end
