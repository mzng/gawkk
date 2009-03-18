class Util::Cache
  def self.collect_videos(videos)
    # gather ids of videos no longer in cache
    ids_of_videos_to_load = Array.new
    videos.each do |video|
      if !Rails.cache.exist?(video.cache_key)
        ids_of_videos_to_load << video.id
      end
    end
    
    # select all videos no longer in cache at once
    Video.find(ids_of_videos_to_load, :include => [:category, {:saved_videos => {:channel => :user}}]).each do |video|
      Rails.cache.write(video.cache_key, video, :expires_in => 1.day)
      Rails.cache.write(video.long_cache_key, video, :expires_in => 1.day)
    end
    
    # collect all of the full videos from cache
    @videos = Array.new(videos.size)
    
    for i in 0..(videos.size - 1)
      @videos[i] = Rails.cache.fetch(videos[i].cache_key, :expires_in => 1.day) do
        Video.find(videos[i].id, :include => [:category, {:saved_videos => {:channel => :user}}])
      end
    end
    
    return @videos
  end
  
  def self.collect_saved_videos(saved_videos)
    # gather ids of videos no longer in cache
    ids_of_videos_to_load = Array.new
    saved_videos.each do |saved_video|
      if !Rails.cache.exist?("videos/#{saved_video.video_id}")
        ids_of_videos_to_load << saved_video.video_id
      end
    end

    # select all videos no longer in cache at once
    Video.find(ids_of_videos_to_load, :include => [:category, {:saved_videos => {:channel => :user}}]).each do |video|
      Rails.cache.write(video.cache_key, video, :expires_in => 1.day)
      Rails.cache.write(video.long_cache_key, video, :expires_in => 1.day)
    end

    # collect all of the full videos from cache
    @videos = Array.new(saved_videos.size)

    for i in 0..(saved_videos.size - 1)
      @videos[i] = Rails.cache.fetch("videos/#{saved_videos[i].video_id}", :expires_in => 1.day) do
        Video.find(saved_videos[i].video_id, :include => [:category, {:saved_videos => {:channel => :user}}])
      end
    end

    return @videos
  end
  
  def self.collect_news_items(news_items)
    # gather ids of news_items no longer in cache
    ids_of_news_items_to_load = Array.new
    news_items.each do |news_item|
      if !Rails.cache.exist?(news_item.cache_key)
        ids_of_news_items_to_load << news_item.id
      end
    end
    
    # select all news_items no longer in cache at once
    NewsItem.find(ids_of_news_items_to_load, :include => :user).each do |news_item|
      Rails.cache.write(news_item.cache_key, news_item, :expires_in => 1.day)
    end
    
    # collect all of the full news_items from cache
    @news_items = Array.new(news_items.size)
    
    for i in 0..(news_items.size - 1)
      @news_items[i] = Rails.cache.fetch(news_items[i].cache_key, :expires_in => 1.day) do
        NewsItem.find(news_items[i].id, :include => :user)
      end
    end
    
    return @news_items
  end
  
  def self.collect_channels(channels)
    # gather ids of channels no longer in cache
    ids_of_channels_to_load = Array.new
    channels.each do |channel|
      if !Rails.cache.exist?(channel.cache_key)
        ids_of_channels_to_load << channel.id
      end
    end
    
    # select all channels no longer in cache at once
    Channel.find(ids_of_channels_to_load, :include => :user).each do |channel|
      Rails.cache.write(channel.cache_key, channel, :expires_in => 1.day)
    end
    
    # collect all of the full channels from cache
    @channels = Array.new(channels.size)
    
    for i in 0..(channels.size - 1)
      @channels[i] = Rails.cache.fetch(channels[i].cache_key, :expires_in => 1.day) do
        Channel.find(channels[i].id, :include => :user)
      end
    end
    
    return @channels
  end
  
  def self.collect_users(users)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    users.each do |user|
      if !Rails.cache.exist?(user.cache_key)
        ids_of_users_to_load << user.id
      end
    end
    
    # select all users no longer in cache at once
    User.find(ids_of_users_to_load).each do |user|
      Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
      Rails.cache.write(user.long_cache_key, user, :expires_in => 1.day)
    end
    
    # collect all of the full users from cache
    @users = Array.new(users.size)
    
    for i in 0..(users.size - 1)
      @users[i] = Rails.cache.fetch(users[i].cache_key, :expires_in => 1.day) do
        User.find(users[i].id)
      end
    end
    
    return @users
  end
  
  def self.collect_users_from_news_items(news_items)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    news_items.each do |news_item|
      if !Rails.cache.exist?("users/#{news_item.user_id}")
        ids_of_users_to_load << news_item.user_id
      end
    end
    
    # select all users no longer in cache at once
    User.find(ids_of_users_to_load).each do |user|
      Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
    end
    
    # collect all of the full users from cache
    @users = Array.new(news_items.size)
    
    for i in 0..(news_items.size - 1)
      @users[i] = Rails.cache.fetch("users/#{news_items[i].user_id}", :expires_in => 1.day) do
        User.find(news_items[i].user_id)
      end
    end
    
    return @users
  end
  
  def self.collect_users_from_subscriptions(subscriptions)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    subscriptions.each do |subscription|
      if !Rails.cache.exist?("users/#{subscription.user_id}")
        ids_of_users_to_load << subscription.user_id
      end
    end
    
    # select all users no longer in cache at once
    User.find(ids_of_users_to_load).each do |user|
      Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
    end
    
    # collect all of the full users from cache
    @users = Array.new(subscriptions.size)
    
    for i in 0..(subscriptions.size - 1)
      @users[i] = Rails.cache.fetch("users/#{subscriptions[i].user_id}", :expires_in => 1.day) do
        User.find(subscriptions[i].user_id)
      end
    end
    
    return @users
  end
end