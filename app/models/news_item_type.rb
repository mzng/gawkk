class NewsItemType < ActiveRecord::Base
  has_many :news_items
  
  
  def self.cached_by_id(id)
    Rails.cache.fetch("news_items_types/#{id}", :expires_in => 1.day) {
      type = NewsItemType.find(id)
      Rails.cache.write("news_item_types/#{type.name}", type, :expires_in => 1.day)
      type
    }
  end
  
  def self.cached_by_name(name)
    Rails.cache.fetch("news_items_types/#{name}", :expires_in => 1.day) {
      type = NewsItemType.find_by_name(name)
      Rails.cache.write(type.cache_key, type, :expires_in => 1.day)
      type
    }
  end
end
