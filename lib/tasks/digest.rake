namespace :digest do
	task :emails => :environment do
	  User.find_in_batches(:conditions => ['feed_owner = false AND digest_email_frequency > 0'], :batch_size => 100) { |users|
	    users.each { |user|
        DigestMailer.deliver_activity(user)
      }
    }
  end
end