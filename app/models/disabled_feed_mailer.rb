class DisabledFeedMailer < ActionMailer::Base
  def notification(users)
    @subject      = "Channel Status (#{users.size.to_s} Channels with disabled Feeds)"
    @body["users"] = users
    @recipients   = "logs@gawkk.com"
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
end
