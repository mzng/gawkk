class RemoveBirthdayFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :birthday
  end

  def self.down
    add_column :users, :birthday, :date
  end
end
