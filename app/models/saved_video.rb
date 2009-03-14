class SavedVideo < ActiveRecord::Base
  belongs_to  :channel, :counter_cache => true
  belongs_to  :video, :counter_cache => true
  
  named_scope :in_channel, lambda {|channel| {:include => :video, :conditions => {:channel_id => channel.id}, :order => 'created_at DESC, id DESC'}}
  named_scope :in_channels, lambda {|channel_ids| {:select => '*, max(created_at) as max_created_at', :conditions => ['channel_id IN (?)', channel_ids], :group => 'video_id', :order => 'max_created_at DESC, id DESC'}}
end
