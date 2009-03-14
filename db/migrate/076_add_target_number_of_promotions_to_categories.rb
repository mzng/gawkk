class AddTargetNumberOfPromotionsToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :target_number_of_promotions, :integer, :default => 0, :null => false
    Category.reset_column_information
    
    Category.find(:all).each do |category|
      category.update_attribute('target_number_of_promotions', category.threshold * 2)
      category.update_attribute('threshold', 2)
    end
  end

  def self.down
    remove_column :categories, :target_number_of_promotions
  end
end
