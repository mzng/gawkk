class AddPositionToFlagTypes < ActiveRecord::Migration
  def self.up
    add_column :flag_types, :position, :integer, :null => false
  end

  def self.down
    remove_column :flag_types, :position
  end
end
