class BackupMailer < ActionMailer::Base
  def database_status_update(backup_files)
    @subject    = "Amazon S3: Database Backups"
    @body["backup_files"] = backup_files
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
