class AddFacebookToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :facebook, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :facebook
  end
end
