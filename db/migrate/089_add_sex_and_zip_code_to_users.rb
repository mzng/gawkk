class AddSexAndZipCodeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :sex, :string, :limit => 1
    add_column :users, :zip_code, :string, :limit => 5
  end

  def self.down
    remove_column :users, :zip_code
    remove_column :users, :sex
  end
end
