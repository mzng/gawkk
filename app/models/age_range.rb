class AgeRange < ActiveRecord::Base
  acts_as_list
  
  has_many :users, :conditions => 'feed_owner = false'
  
  def self.collect
    find(:all, :order => 'position').collect{|age_range| [age_range.range, age_range.id]}
  end
end
