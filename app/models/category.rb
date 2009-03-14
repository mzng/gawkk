class Category < ActiveRecord::Base
  acts_as_list
  
  has_many :videos
  
  def to_param
    self.slug
  end
  
  def self.allowed_on_front_page
    Category.find(:all, :conditions => 'allowed_on_front_page = true').collect{|category| category.id}
  end
end
