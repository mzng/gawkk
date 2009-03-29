class MissingImageDetectionMailer < ActionMailer::Base
  def log(count, fixed, urls)
    @subject    = "Missing Images Fixed (#{count.to_s} processed, #{fixed.to_s} fixed)"
    @body["urls"] = urls
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
