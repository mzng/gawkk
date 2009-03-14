class AddMatureToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :mature, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :channels, :mature
  end
end
