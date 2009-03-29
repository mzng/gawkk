class MissingImageDetectionMailer < ActionMailer::Base
  def log(count, video_urls)
    @subject    = "Missing Images Fixed (#{count.to_s} processed)"
    @body["video_urls"] = video_urls
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
