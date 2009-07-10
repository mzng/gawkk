class SubscriptionMessage < ActiveRecord::Base
  belongs_to :user
  belongs_to :saved_video
  belongs_to :video
  
  named_scope :recent, :order => 'saved_video_id DESC'
  named_scope :for_user, lambda {|user| {:conditions => ['user_id = ?', user.id]}}
  named_scope :with_max_id_of, lambda {|max_id| {:conditions => ['saved_video_id <= ?', max_id]}}
  
  
  def before_create
    return (SubscriptionMessage.count(:all, :conditions => {:user_id => self.user_id, :saved_video_id => self.saved_video_id}) > 0) ? false : true
  end
end
