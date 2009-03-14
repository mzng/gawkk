class AddDeletedToFlagTypes < ActiveRecord::Migration
  def self.up
    add_column :flag_types, :deleted, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :flag_types, :deleted
  end
end
