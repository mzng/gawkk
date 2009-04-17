namespace :digest do
	task :emails => :environment do
    User.find(:all, :conditions => ['feed_owner = false AND digest_email_frequency > 0'], :order => 'created_at ASC').each do |user|
      begin
        DigestMailer.deliver_activity(user)
        puts "PASS: #{user.username}"
      rescue
        puts "FAIL: #{user.username}"
      end
    end
  end
  
  task :test => :environment do
	  DigestMailer.deliver_activity(User.find_by_slug('tsmango'))
  end
end