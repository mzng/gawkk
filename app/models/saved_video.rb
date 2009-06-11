class SavedVideo < ActiveRecord::Base
  belongs_to  :channel, :counter_cache => :saves_count
  belongs_to  :video, :counter_cache => :saves_count
  
  named_scope :in_channel, lambda {|channel| {:include => :video, :conditions => {:channel_id => channel.id}, :order => 'created_at DESC, id DESC'}}
  named_scope :in_channels, lambda {|channel_ids| {:select => '*, max(id) as max_id', :conditions => ['channel_id IN (?)', channel_ids], :group => 'video_id', :order => 'max_id DESC'}}
  named_scope :with_max_id_of, lambda {|max_id| {:conditions => ['id <= ?', max_id]}}
end
