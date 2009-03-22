class DiscussionMailer < ActionMailer::Base
  def notification(details)
    @subject      = "#{details[:sender].username} has posted a reply to a video discussion you're following on Gawkk"
    @body["details"] = details
    @recipients   = details[:recipient].email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
end
