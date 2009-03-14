class AddFlagsCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :flags_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :flags_count
  end
end
