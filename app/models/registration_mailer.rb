class RegistrationMailer < ActionMailer::Base
  def notification(user)
    @subject      = 'Welcome to the Gawkk video network'
    @body["user"] = user
    @recipients   = user.email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
end
