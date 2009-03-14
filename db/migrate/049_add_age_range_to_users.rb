class AddAgeRangeToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :age_range_id, :integer
  end

  def self.down
    remove_column :users, :age_range_id
  end
end
