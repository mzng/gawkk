class ImportMailer < ActionMailer::Base
  def thumbnail_failure_notification
    @subject    = "[AUTOMATIC SHUTDOWN] All Feed Importers Have Been Stopped - " + Time.now.strftime("%I:%M %p")
    @body       = "All Feed Importers have been stopped because a possible problem with the NFS mount was detected. Better safe than sorry!"
    @recipients = "errors@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
