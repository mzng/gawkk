namespace :messaging do
  namespace :subscriptions do
    task :bootstrap => :environment do
      channels = Channel.find(:all, :conditions => {:user_owned => false}, :order => 'subscriptions_count ASC')
      
      channels.each_with_index do |channel, i|
        subscriber_ids = Subscription.for_channel(channel).all.collect{|subscriber| subscriber.user_id}
        
        if subscriber_ids.size > 0
          saved_videos = channel.videos(:limit => 10)

          puts "Processing SubscriptionMessages for #{channel.proper_name} (#{(i + 1).to_s} of #{channels.size.to_s})"
          puts "  => #{subscriber_ids.size.to_s} Subscriber#{subscriber_ids.size > 1 ? 's' : ''}"
          puts "  => #{saved_videos.size.to_s} Video#{saved_videos.size > 1 ? 's' : ''}"

          saved_videos.each do |saved_video|
            saved_video.generate_messages_for_subscribers!
          end
        end
      end
    end
  end
end