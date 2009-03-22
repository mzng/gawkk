class DiscussionMailer < ActionMailer::Base
  def notification(details)
    @subject      = "#{details[:sender].username} replied to the Gawkk discussion: \"#{details[:video].title}\""
    @body["details"] = details
    @recipients   = details[:recipient].email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
end
