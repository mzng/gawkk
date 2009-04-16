class DigestMailer < ActionMailer::Base
  helper :application
  
  def activity(user)
    @subject      = "New Videos and Updates from your Friends at Gawkk"
    @body["user"] = user
    @recipients   = user.email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/html"
  end
end
