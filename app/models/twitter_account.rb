class TwitterAccount < ActiveRecord::Base
  belongs_to :user
  # has_many :tweets, :dependent => :destroy
  
  def before_save
    self.authenticated = Twitter::Client.new.authenticate?(self.username, self.password)
    return true
  end
end
