class ActivityMessage < ActiveRecord::Base
  belongs_to :user
  belongs_to :news_item
  
  named_scope :recent, :order => 'news_item_id DESC'
  named_scope :for_user, lambda {|user| {:conditions => ['user_id = ?', user.id]}}
  named_scope :grouped, :conditions => {:hidden => false}
end
