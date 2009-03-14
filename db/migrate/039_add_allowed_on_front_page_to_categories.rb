class AddAllowedOnFrontPageToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :allowed_on_front_page, :boolean, :default => true, :null => false
  end

  def self.down
    remove_column :categories, :allowed_on_front_page
  end
end
