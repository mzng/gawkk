class Util::Cache
  def self.increment(key, amount = 1)
    if (value = Rails.cache.read(key)).nil?
      Rails.cache.write(key, (value = amount), :expires_in => 1.week)
    else
      Rails.cache.write(key, (value = value + amount), :expires_in => 1.week)
    end
    
    return value
  end
  
  def self.decrement(key, amount = 1)
    if (value = Rails.cache.read(key)).nil?
      value = 0
    else
      Rails.cache.write(key, (value = value - amount), :expires_in => 1.week)
    end
    
    return value
  end
  
  
  def self.collect_videos(videos)
    # gather ids of videos no longer in cache
    ids_of_videos_to_load = Array.new
    videos.each do |video|
     # if !Rails.cache.exist?(video.cache_key)
        ids_of_videos_to_load << video.id
     # end
    end
    
    # select all videos no longer in cache at once
    @videos = Video.find(ids_of_videos_to_load, :include => [:category, :posted_by, {:saved_videos => {:channel => :user}}])#.each do |video|
    #  Rails.cache.write(video.cache_key, video, :expires_in => 1.day)
    #  Rails.cache.write(video.long_cache_key, video, :expires_in => 1.day)
    #end
    
    # collect all of the full videos from cache
#    @videos = Array.new(videos.size)
    
#    for i in 0..(videos.size - 1)
#      @videos[i] = Rails.cache.fetch(videos[i].cache_key, :expires_in => 1.day) do
#        Video.find(videos[i].id, :include => [:category, :posted_by, {:saved_videos => {:channel => :user}}])
#      end
#    end
    
    return @videos
  end
  
  def self.collect_saved_videos(saved_videos)
    # gather ids of videos no longer in cache
    ids_of_videos_to_load = Array.new
    saved_videos.each do |saved_video|
  #    if !Rails.cache.exist?("videos/#{saved_video.video_id}")
        ids_of_videos_to_load << saved_video.video_id
  #    end
    end

    # select all videos no longer in cache at once
   @videos = Video.find(ids_of_videos_to_load, :include => [:category, :posted_by, {:saved_videos => {:channel => :user}}])#.each do |video|
#      Rails.cache.write(video.cache_key, video, :expires_in => 1.day)

#   Rails.cache.write(video.long_cache_key, video, :expires_in => 1.day)

#  end

    # collect all of the full videos from cache
#    @videos = Array.new(saved_videos.size)

#    for i in 0..(saved_videos.size - 1)
#      @videos[i] = Rails.cache.fetch("videos/#{saved_videos[i].video_id}", :expires_in => 1.day) do
#        Video.find(saved_videos[i].video_id, :include => [:category, :posted_by, {:saved_videos => {:channel => :user}}])
#      end
#    end

    return @videos
  end
  
  def self.collect_videos_from_subscription_messages(subscription_messages)
    # gather ids of videos no longer in cache
    ids_of_videos_to_load = Array.new
    subscription_messages.each do |subscription_message|
   #   if !Rails.cache.exist?("videos/#{subscription_message.video_id}")
        ids_of_videos_to_load << subscription_message.video_id
   #   end
    end

    # select all videos no longer in cache at once
  @videos =  Video.find(ids_of_videos_to_load, :include => [:category, {:saved_videos => {:channel => :user}}])#.each do |video|
#      Rails.cache.write(video.cache_key, video, :expires_in => 1.day)
#      Rails.cache.write(video.long_cache_key, video, :expires_in => 1.day)
#    end

    # collect all of the full videos from cache
 #   @videos = Array.new(subscription_messages.size)

  #  for i in 0..(subscription_messages.size - 1)
  #    @videos[i] = Rails.cache.fetch("videos/#{subscription_messages[i].video_id}", :expires_in => 1.day) do
  #      Video.find(subscription_messages[i].video_id, :include => [:category, {:saved_videos => {:channel => :user}}])
  #    end
  #  end

    return @videos
  end
  
  def self.collect_news_items(news_items)
    related_news_items = Hash.new
    
    # if we have max_ids let's cache those related news_items as well
    ids_of_news_items_to_load = Array.new
    news_items.each do |news_item|
      if !(news_item.latest_related_id = news_item.max_id.to_i).nil?
        if !Rails.cache.exist?("news_items/#{news_item.latest_related_id}")
          ids_of_news_items_to_load << news_item.latest_related_id
        end
      end
    end
    
    # remove duplicates that may have been caused by max_ids
    ids_of_news_items_to_load.uniq!
    
    # select all news_items no longer in cache at once
    NewsItem.find(ids_of_news_items_to_load, :include => [:news_item_type, :user, :reportable]).each do |news_item|
      Rails.cache.write(news_item.cache_key, news_item, :expires_in => 1.day)
    end
    
    news_items.each do |news_item|
      if !news_item.latest_related_id.nil?
        news_item.latest_related = Rails.cache.fetch("news_items/#{news_item.latest_related_id}", :expires_in => 1.day) do
          NewsItem.find(news_item.latest_related_id, :include => [:news_item_type, :user, :reportable])
        end
        related_news_items[news_item.id.to_s] = news_item.latest_related
      end
    end
    
    
    # gather ids of news_items no longer in cache
    ids_of_news_items_to_load = Array.new
    news_items.each do |news_item|
      if !Rails.cache.exist?(news_item.cache_key)
        ids_of_news_items_to_load << news_item.id
      end
    end
    
    # select all news_items no longer in cache at once
    NewsItem.find(ids_of_news_items_to_load, :include => [:news_item_type, :user, :reportable]).each do |news_item|
      Rails.cache.write(news_item.cache_key, news_item, :expires_in => 1.day)
    end
    
    # collect all of the full news_items from cache
    @news_items = Array.new(news_items.size)
    
    for i in 0..(news_items.size - 1)
      @news_items[i] = Rails.cache.fetch(news_items[i].cache_key, :expires_in => 1.day) do
        NewsItem.find(news_items[i].id, :include => [:news_item_type, :user, :reportable])
      end
    end
    
    @news_items.each do |news_item|
      news_item.latest_related = related_news_items[news_item.id.to_s]
    end
    
    return @news_items
  end
  
  def self.collect_news_items_from_activity_messages(activity_messages)
    # gather ids of news_items no longer in cache
    ids_of_news_items_to_load = Array.new
    activity_messages.each do |activity_message|
      if !Rails.cache.exist?("news_items/#{activity_message.news_item_id}")
        ids_of_news_items_to_load << activity_message.news_item_id
      end
    end
    
    # select all news_items no longer in cache at once
    NewsItem.find(ids_of_news_items_to_load, :include => [:news_item_type, :user, :reportable]).each do |news_item|
      Rails.cache.write(news_item.cache_key, news_item, :expires_in => 1.day)
    end
    
    # collect all of the full news_items from cache
    @news_items = Array.new(activity_messages.size)
    
    for i in 0..(activity_messages.size - 1)
      @news_items[i] = Rails.cache.fetch("news_items/#{activity_messages[i].news_item_id}", :expires_in => 1.day) do
        NewsItem.find(activity_messages[i].news_item_id, :include => [:news_item_type, :user, :reportable])
      end
    end
    
    @news_items.each do |news_item|
      news_item.latest_related = news_item
    end
    
    return @news_items
  end
  
  def self.collect_comments(comments)
    # gather ids of comments no longer in cache
    ids_of_comments_to_load = Array.new
    comments.each do |comment|
      if !Rails.cache.exist?(comment.cache_key)
        ids_of_comments_to_load << comment.id
      end
    end
    
    # select all comments no longer in cache at once
    Comment.find(ids_of_comments_to_load, :include => [:user, :commentable]).each do |comment|
      Rails.cache.write(comment.cache_key, comment, :expires_in => 1.day)
    end
    
    # collect all of the full comments from cache
    @comments = Array.new(comments.size)
    
    for i in 0..(comments.size - 1)
      @comments[i] = Rails.cache.fetch(comments[i].cache_key, :expires_in => 1.day) do
        Comment.find(comments[i].id, :include => [:user, :commentable])
      end
    end
    
    return @comments
  end
  
  def self.collect_channels(channels)
    # gather ids of channels no longer in cache
    ids_of_channels_to_load = Array.new
    channels.each do |channel|
 #     if !Rails.cache.exist?(channel.cache_key)
        ids_of_channels_to_load << channel.id
#      end
    end
    
    # select all channels no longer in cache at once
@channels =    Channel.find(ids_of_channels_to_load, :include => :user)#.each do |channel|
 #     Rails.cache.write(channel.cache_key, channel, :expires_in => 1.day)
 #   end
    
    # collect all of the full channels from cache
#    @channels = Array.new(channels.size)
    
#    for i in 0..(channels.size - 1)
#      @channels[i] = Rails.cache.fetch(channels[i].cache_key, :expires_in => 1.day) do
#        Channel.find(channels[i].id, :include => :user)
#      end
#    end
    
    return @channels
  end
  
  def self.collect_channels_from_saved_videos(saved_videos)
    # gather ids of channels no longer in cache
    ids_of_channels_to_load = Array.new
    saved_videos.each do |saved_video|
 
 #     if !Rails.cache.exist?("channels/#{saved_video.channel_id}")
        ids_of_channels_to_load << saved_video.channel_id
 #     end
    end
    
    # select all channels no longer in cache at once
@channels =    Channel.find(ids_of_channels_to_load, :include => :user)#.each do |channel|
#      Rails.cache.write(channel.cache_key, channel, :expires_in => 1.day)
#    end
    
    # collect all of the full channels from cache
#    @channels = Array.new(saved_videos.size)
    
#    for i in 0..(saved_videos.size - 1)
#      @channels[i] = Rails.cache.fetch("channels/#{saved_videos[i].channel_id}", :expires_in => 1.day) do
#        Channel.find(saved_videos[i].channel_id, :include => :user)
#      end
#    end
    
    return @channels
  end
  
  def self.collect_users(users)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    users.each do |user|
    #  if !Rails.cache.exist?(user.cache_key)
        ids_of_users_to_load << user.id
    #  end
    end
    
    # select all users no longer in cache at once
   @users =  User.find(ids_of_users_to_load)#.each do |user|
   #   Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
   #   Rails.cache.write(user.long_cache_key, user, :expires_in => 1.day)
   # end
    
    # collect all of the full users from cache
    #@users = Array.new(users.size)
    
   # for i in 0..(users.size - 1)
   #   @users[i] = Rails.cache.fetch(users[i].cache_key, :expires_in => 1.day) do
   #     User.find(users[i].id)
   #   end
   # end
    
    return @users
  end
  
  def self.collect_users_from_news_items(news_items)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    news_items.each do |news_item|
    #  if !Rails.cache.exist?("users/#{news_item.user_id}")
        ids_of_users_to_load << news_item.user_id
    #  end
    end
    
    # select all users no longer in cache at once
    @users = User.find(ids_of_users_to_load)#.each do |user|
#      Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
#    end
    
    # collect all of the full users from cache
#    @users = Array.new(news_items.size)
    
#    for i in 0..(news_items.size - 1)
#      @users[i] = Rails.cache.fetch("users/#{news_items[i].user_id}", :expires_in => 1.day) do
#        User.find(news_items[i].user_id)
#      end
#    end
    
    return @users
  end
  
  def self.collect_users_from_subscriptions(subscriptions)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    subscriptions.each do |subscription|
   #   if !Rails.cache.exist?("users/#{subscription.user_id}")
        ids_of_users_to_load << subscription.user_id
   #   end
    end
    
    # select all users no longer in cache at once
    @users = User.find(ids_of_users_to_load)#.each do |user|
#      Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
#    end
    
    # collect all of the full users from cache
 #   @users = Array.new(subscriptions.size)
    
 #   for i in 0..(subscriptions.size - 1)
 #     @users[i] = Rails.cache.fetch("users/#{subscriptions[i].user_id}", :expires_in => 1.day) do
  #      User.find(subscriptions[i].user_id)
  #    end
  #  end
    
    return @users
  end
  
  def self.collect_users_from_comments(comments)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    comments.each do |comment|
   #   if !Rails.cache.exist?("users/#{comment.user_id}")
        ids_of_users_to_load << comment.user_id
   #   end
    end
    
    # select all users no longer in cache at once
   @users = User.find(ids_of_users_to_load)#.each do |user|
    #  Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
    #end
    
    # collect all of the full users from cache
#    @users = Array.new(comments.size)
    
#    for i in 0..(comments.size - 1)
#      @users[i] = Rails.cache.fetch("users/#{comments[i].user_id}", :expires_in => 1.day) do
#        User.find(comments[i].user_id)
#      end
#    end
    
    return @users
  end
  
  def self.collect_users_from_likes(likes)
    # gather ids of users no longer in cache
    ids_of_users_to_load = Array.new
    likes.each do |like|
  #    if !Rails.cache.exist?("users/#{like.user_id}")
        ids_of_users_to_load << like.user_id
  #    end
    end
    
    # select all users no longer in cache at once
@users =    User.find(ids_of_users_to_load)#.each do |user|
   #   Rails.cache.write(user.cache_key, user, :expires_in => 1.day)
   # end
    
    # collect all of the full users from cache
#    @users = Array.new(likes.size)
    
#    for i in 0..(likes.size - 1)
#      @users[i] = Rails.cache.fetch("users/#{likes[i].user_id}", :expires_in => 1.day) do
#        User.find(likes[i].user_id)
#      end
#    end
    
    return @users
  end
end
