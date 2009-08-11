namespace :digest do
	task :emails => :environment do
	  user_count = User.count(:all, :conditions => ['feed_owner = false AND digest_email_frequency > 0'], :order => 'created_at ASC')
    puts "Preparing to deliver #{user_count.to_s} digest emails..."
    
    for page in (1..(user_count / 100 + 1)).to_a
	    puts "Processing page #{page.to_s}..."
	    
	    User.find(:all, :conditions => ['feed_owner = false AND digest_email_frequency > 0'], :order => 'created_at ASC', :limit => 100, :offset => (100 * (page - 1))).each do |user|
  	    begin
          DigestMailer.deliver_activity(user)
        rescue
        end
        
        sleep(1)
      end
    end
  end
  
  task :test => :environment do
	  DigestMailer.deliver_activity(User.find_by_slug('tsmango'))
  end
end