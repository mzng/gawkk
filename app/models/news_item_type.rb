class NewsItemType < ActiveRecord::Base
  has_many :news_items
end
