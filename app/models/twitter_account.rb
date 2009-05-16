class TwitterAccount < ActiveRecord::Base
  belongs_to :user
  # has_many :tweets, :dependent => :destroy
  
  def before_save
    if self.access_token.blank?
      self.authenticated = Twitter::Client.new.authenticate?(self.username, self.password)
    end
    
    return true
  end
  
  def dispatcher
    if self.access_token.blank?
      TwitterDispatch.new(:basic, self.username, self.password)
    end
  end
end
