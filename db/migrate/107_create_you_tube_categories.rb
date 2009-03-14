class CreateYouTubeCategories < ActiveRecord::Migration
  def self.up
    create_table :you_tube_categories do |t|
      t.string  :name
      t.integer :category_id
    end
  end

  def self.down
    drop_table :you_tube_categories
  end
end
