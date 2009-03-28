class BackupMailer < ActionMailer::Base
  def logs(stats)
    @subject    = "Daily Amazon S3 Statistics"
    @body["stats"]  = stats
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
