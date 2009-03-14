class AddComparableToChannels < ActiveRecord::Migration
  def self.up
    add_column :channels, :comparable, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :channels, :comparable
  end
end
