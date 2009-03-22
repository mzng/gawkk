class FeedImporterReport < ActiveRecord::Base
  belongs_to  :feed
  has_many    :videos, :dependent => :nullify
  
  def after_save
    if self.videos_count > 0
      Channel.owned_by(self.feed.owned_by).first.update_attribute('last_save_at', Time.now)
    end
  end
end
