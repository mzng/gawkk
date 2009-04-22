class ImportMailer < ActionMailer::Base
  def automatic_shutdown_notification(video)
    @subject      = "[AUTOMATIC SHUTDOWN] All Feed Importers Have Been Stopped - " + Time.now.strftime("%I:%M %p")
    @body["video"] = video
    @recipients   = "errors@gawkk.com"
    @from         = "\"Gawkk\" <notifier@gawkk.com>"
    headers         "Reply-to" => "notifier@gawkk.com"
    @sent_on      = Time.now
    @content_type = "text/plain"
  end
end
