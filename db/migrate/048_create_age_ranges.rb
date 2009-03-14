class CreateAgeRanges < ActiveRecord::Migration
  def self.up
    create_table :age_ranges do |t|
      t.column :position, :integer
      t.column :range, :string, :null => false
    end
  end

  def self.down
    drop_table :age_ranges
  end
end
