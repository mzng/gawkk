class AddSafeSearchToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :safe_search, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :users, :safe_search
  end
end
