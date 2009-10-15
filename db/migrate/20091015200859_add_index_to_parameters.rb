class AddIndexToParameters < ActiveRecord::Migration
  def self.up
    add_index :parameters, :name
  end

  def self.down
    remove_index :parameters, :name
  end
end
