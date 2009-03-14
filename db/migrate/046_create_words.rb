class CreateWords < ActiveRecord::Migration
  def self.up
    create_table :words do |t|
      t.column :word_list_id, :integer, :null => false
      t.column :value, :string
    end
  end

  def self.down
    drop_table :words
  end
end
