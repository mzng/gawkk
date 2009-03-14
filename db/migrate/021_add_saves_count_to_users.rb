class AddSavesCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :saves_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :saves_count
  end
end
