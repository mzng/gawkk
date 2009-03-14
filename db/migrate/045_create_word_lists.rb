class CreateWordLists < ActiveRecord::Migration
  def self.up
    create_table :word_lists do |t|
      t.column :name, :string
    end
  end

  def self.down
    drop_table :word_lists
  end
end
