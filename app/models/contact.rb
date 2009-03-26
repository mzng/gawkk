class Contact < ActiveRecord::Base
  belongs_to :user
  
  validates_presence_of   :email, :message => "can't be blank"
  validates_uniqueness_of :email, :message => "must be unique"
  validates_format_of     :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i
  
  named_scope :of_user, lambda {|user| {:conditions => ['user_id = ?', user.id]}}
  
  
  def <=>(obj)
    if obj.class == User
      self.email.downcase <=> obj.username.downcase
    else
      self.email.downcase <=> obj.email.downcase
    end
  end
end
