class Category < ActiveRecord::Base
  acts_as_list
  
  has_many :videos
  
  def to_param
    self.slug
  end
  
  
  def self.all_cached
    Rails.cache.fetch("categories/all", :expires_in => 1.week) {
      Category.all(:order => 'name')
    }
  end
  
  def self.allowed_in_header
    Rails.cache.fetch("categories/allowed-in-header", :expires_in => 1.week) {
      categories = Array.new
      
      categories << Category.find_by_slug('news-politics')
      categories.last.name = 'News'
      
      categories << Category.find_by_slug('television-shows')
      categories.last.name = 'TV Shows'
      
      categories << Category.find_by_slug('movies-previews-trailers')
      categories.last.name = 'Movies'
      
      categories << Category.find_by_slug('music-dancing')
      categories.last.name = 'Music'
      
      categories
    }
  end
  
  def self.allowed_on_front_page
    Rails.cache.fetch("categories/allowed-on-front-page", :expires_in => 1.week) {
      Category.find(:all, :conditions => 'allowed_on_front_page = true', :order => 'name')
    }
  end
  
  def self.allowed_on_front_page_ids
    Category.allowed_on_front_page.collect{|category| category.id}
  end
end
