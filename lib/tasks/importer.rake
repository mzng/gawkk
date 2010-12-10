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
      Kernel.system("ruby script/runner -e #{Rails.env.to_s} \"Feed.import(false)\" &")
      Kernel.system("ruby script/runner -e #{Rails.env.to_s} \"Feed.import(false)\" &")
    end
  end
  
  task :digg => :environment do
    Feed.find_by_url('http://feeds.digg.com/digg/videos/popular.rss').import(nil, true)
  end
end
