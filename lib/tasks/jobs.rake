namespace :jobs do
	task :process => :environment do
    while true
      # Find a queued Job to process
      if Parameter.status?('job_queue_enabled') and (job = Job.dequeue)
        begin
          # Place the Job in the 'process' state
          job.process!
          
          # For now, there's only a single JobType
          job.processable.generate_messages_for_followers!
          
          # Place this Job in the 'completed' state
          job.complete!
        rescue
          # Place this Job in the 'failed' state
          job.fail!
        end
      else
        sleep(15)
      end
    end
  end
  
  task :bootstrap => :environment do
    NewsItem.find(:all, :conditions => ['created_at > ?', 60.days.ago], :order => 'created_at ASC').each do |news_item|
      news_item.generate_message_for_user!
      Job.enqueue(:processable => news_item)
    end
  end
end