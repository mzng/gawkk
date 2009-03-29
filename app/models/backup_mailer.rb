class BackupMailer < ActionMailer::Base
  def database_status_update(files)
    @subject    = "Amazon S3: Database Backup Status"
    @body["files"] = files
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
  
  def image_status_update(files)
    @subject    = "Amazon S3: Image Backup Status (#{files.size} new)"
    @body["files"] = files
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
