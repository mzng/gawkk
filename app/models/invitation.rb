class Invitation < ActiveRecord::Base
  belongs_to :host, :class_name => "User", :foreign_key => "host_id"
  belongs_to :invitee, :class_name => "User", :foreign_key => "invitee_id"
  
  validates_presence_of :host_id
  validates_presence_of :invitee_email
  
  def after_create
    InvitationMailer.deliver_invitation(self)
    
    return true
  end
  
  def accepted_by(user = nil)
    if !user.nil?
      self.accepted = true
      self.accepted_at = Time.now
      self.invitee_id = user.id
      self.save
      
      self.invitee.follow(self.host)
      self.host.follow(self.invitee)
    end
  end
end
