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
  
  def self.allowed_on_front_page
    Rails.cache.fetch("categories/allowed-on-front-page", :expires_in => 1.week) {
      Category.find(:all, :conditions => 'allowed_on_front_page = true', :order => 'name')
    }
  end
  
  def self.allowed_on_front_page_ids
    Category.allowed_on_front_page.collect{|category| category.id}
  end
end
