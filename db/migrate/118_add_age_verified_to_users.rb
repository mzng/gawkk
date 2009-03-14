class AddAgeVerifiedToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :age_verified, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :age_verified
  end
end
