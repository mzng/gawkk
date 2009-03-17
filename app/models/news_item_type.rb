class NewsItemType < ActiveRecord::Base
  has_many :news_items
  
  
  def self.cached_by_name(name)
    Rails.cache.fetch("news_items_types/#{name}", :expires_in => 1.day) {
      NewsItemType.find_by_name(name)
    }
  end
end
