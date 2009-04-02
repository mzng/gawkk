class ImportMailer < ActionMailer::Base
  def thumbnail_failure_notification
    @subject    = "[FAILURE] A Feed Importer Has Been Stopped at " + Time.now.strftime("%I:%M %p")
    @body       = "A Feed Importer Has Been Stopped because we were missing a thumbnail that we thought we had."
    @recipients = "errors@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
