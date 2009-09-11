class AddPopularToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :popular, :boolean, :default => false, :null => false
    
    Category.reset_column_information
    Category.find(:all, :conditions => ['slug IN (?)', ['celebrities-entertainment', 'comedy', 'commercials', 'movies-previews-trailers', 'music-dancing', 'odd-outrageous', 'technology-internet-science', 'television-shows']]).each do |category|
      category.update_attribute(:popular, true)
    end
  end

  def self.down
    remove_column :categories, :popular
  end
end