class ProcessMailer < ActionMailer::Base
  def restart_notification(process_name)
    @subject    = "Process Monitor: A Background Process has been restarted"
    @body       = "#{Time.now.strftime("%m/%d/%Y at %I:%M%p")}\n\n#{process_name} has been restarted"
    @recipients = "logs@gawkk.com"
    @from       = "\"Gawkk\" <notifier@gawkk.com>"
    headers       "Reply-to" => "notifier@gawkk.com"
    @sent_on    = Time.now
  end
end
