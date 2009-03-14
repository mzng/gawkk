class AddViewsCountToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :views_count, :integer, :default => 0, :null => false
  end

  def self.down
    remove_column :users, :views_count
  end
end
