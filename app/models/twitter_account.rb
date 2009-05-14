class TwitterAccount < ActiveRecord::Base
  belongs_to :user
  # has_many :tweets, :dependent => :destroy
  
  def before_save
    self.authenticated = Twitter::Client.new.authenticate?(self.username, self.password)
    
    return true
  end
  
  def dispatcher
    if self.access_token.blank?
      TwitterDispatch.new(:basic, self.username, self.password)
    else
      TwitterDispatch.new(:oauth, Util::Twitter.config[:key], Util::Twitter.config[:secret], self.access_token, self.access_secret)
    end
  end
end
