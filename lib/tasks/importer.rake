namespace :importer do
  task :restart => :environment do
    running = false
    
    output = `ps aux | grep "ruby script/runner -e #{Rails.env.to_s} Feed.import(false)"`.split("\n")
    output.each do |process|
      if !process[/grep/]
        running = true
      end
    end
    
    if !running and Parameter.status?('feed_importer_status')
      Kernel.system("ruby script/runner -e #{Rails.env.to_s} \"Feed.import(false)\" &")
      ProcessMailer.deliver_restart_notification('runner -e production Feed.import(false)')
    end
  end
end