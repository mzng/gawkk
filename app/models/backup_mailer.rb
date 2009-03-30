class BackupMailer < ActionMailer::Base
  def status_update(files)
    @subject    = "Amazon S3: Backup Status (#{files[:database].size} DB Backups; #{files[:images].size} New Images)"
    @body["files"] = files
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
