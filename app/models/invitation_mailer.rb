class InvitationMailer < ActionMailer::Base
  def invitation(invitation)
    @subject      = "You have been invited to join #{invitation.host.name or invitation.host.username} on Gawkk"
    @body["invitation"] = invitation
    @recipients   = invitation.invitee_email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/html"
  end
end
