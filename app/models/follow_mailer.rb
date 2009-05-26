class FollowMailer < ActionMailer::Base
  def notification(friendship)
    @subject      = "#{friendship.user.username} has started following you on Gawkk"
    @body["friendship"] = friendship
    @recipients   = friendship.friend.email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
  
  def summary(friendships)
    @subject      = "#{friendships.size.to_s} new people have started following you on Gawkk"
    @body["friendships"] = friendships
    @recipients   = friendships.first.friend.email
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
end
