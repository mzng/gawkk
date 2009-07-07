namespace :jobs do
	task :process => :environment do
    while true
      begin
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
      rescue
        sleep(30)
      end
    end
  end
  
  namespace :bootstrap do
    task :everyone => :environment do
      NewsItem.find(:all, :conditions => ['created_at > ?', 60.days.ago], :order => 'created_at ASC').each do |news_item|
        news_item.generate_message_for_user!
        Job.enqueue(:processable => news_item)
      end
    end
  
    task :default => :environment do
      default = User.find_by_username('default')
      
      NewsItem.find(:all, :conditions => ['user_id IN (?) AND created_at > ?', User.default_followings.collect{|u| u.id}, 60.days.ago], :order => 'created_at ASC').each do |news_item|
        news_item.generate_message_for_user!(default)
      end
    end
  end
end

namespace :job do
  namespace :queue do
    task :restart => :environment do
      running = false
      
      output = `ps aux | grep "rake jobs:process"`.split("\n")
      output.each do |process|
        if !process[/grep/]
          running = true
        end
      end
      
      if !running
        Kernel.system("rake jobs:process RAILS_ENV=#{Rails.env.to_s} &")
        ProcessMailer.deliver_restart_notification('rake jobs:process')
      end
    end
  end
end