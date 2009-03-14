class AddThumbnailToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :thumbnail, :string
  end

  def self.down
    remove_column :categories, :thumbnail
  end
end
