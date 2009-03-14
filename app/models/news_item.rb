class NewsItem < ActiveRecord::Base
  belongs_to :news_item_type
  belongs_to :user
  belongs_to :reportable, :polymorphic => true
  
  def self.grouped_activity(user_ids, options = {})
    # Speed and clean this method up with the caching system
    activity_types = NewsItemType.find(:all, :conditions => ['kind = ?', 'about a user']).collect{|type| type.id}
    
    options[:order] = 'max_created_at DESC'
    
    union([{:select => '*, max(created_at) AS max_created_at', 
            :conditions => ["news_item_type_id IN (?) AND reportable_type = 'Video' AND user_id IN (?) AND hidden = false", activity_types, user_ids], 
            :group => 'reportable_id'},
           {:select => '*, created_at AS max_created_at', 
            :conditions => ["news_item_type_id IN (?) AND reportable_type != 'Video' AND user_id IN (?) AND hidden = false", activity_types, user_ids]}], 
            options)
  end
end
