module VideosHelper
  def intelligent_author_avatar(author)
    image = image_tag(author.thumbnail.blank? ? 'profile-pic.jpg' : author.thumbnail, :class => 'avatar')
    if author.feed_owner?
      link_to image, user_channel_path(author)
    else
      image
    end
  end

  def make_a_cloud(searches)
    max, min = 0, 0
  searches.each { |t|
    max = t.count.to_i if t.count.to_i > max
    min = t.count.to_i if t.count.to_i < min
  }

  sizes = ["1", "1.2", "1.4","1.6", "1.8", "2.0","2", "2.2", "2.4", "2.6"]
  divisor = ((max - min) / sizes.size) + 1


  res = []

  searches.each { |t|
    res << link_to(t.query, "http://#{BASE_URL}/search?q=#{t.query}", :style => "font-size: #{sizes[(t.count.to_i - min) / divisor]}em")
  }
  res
  end

  def topic_crumb_params(channel)
    category_id = !channel.category.blank? ? channel.category.to_i : nil

    if category_id.nil?
      { :name => "Variety", :params => smart_category_link(Category.find(15), nil, true) }
    else
      category = Category.find(category_id)
      { :name => category.name, :params => smart_category_link(category, nil, true) }
    end
  end


  def link_for_channel_name(video)
    smart_channel_link video.posted_by, video.posted_by.channels.first
  end

  def root_link(url_only = false)
    url = "http://#{BASE_URL}"

    url_only ? url : link_to("Home", url)
  end

  def intelligent_author_name(author)
    if author.feed_owner?
      link_to author.username, user_channel_path(author)
    else
      author.username
    end
  end

  def smart_channel_link(user, channel, url_only = false, page = nil, newest = nil)
    url = "http://"
    subdomain = false
    splits = channel.category_ids.split ' '
    
    splits.each do |s|
      if s == '7'
        url += "tv."
        subdomain = true

        break
      elsif s == '26'
        url += "movies."
        subdomain = true
        break
      end
    end

    unless subdomain
      if splits[0]
        category = Category.find(splits[0])
      else 
        category = Category.find_by_slug("uncategorized")
      end
      

    end

    url += "#{BASE_URL}/"
    url += "#{category.slug}/" unless subdomain
    url += "#{user.slug}"
    url += "?page=#{page}" if page
    url += "?newest=true" if newest && !page
    url += "&newest=true" if newest && page

    url_only ? url : link_to(channel.name, url)
  end


  def smart_channel_topic_link(topic, character = nil, url_only = false)
    url = "http://"
    subdomain = false
    if topic
      if topic.slug == 'television-shows'
        url += "tv."
        subdomain = true
      elsif topic.slug == 'movies-previews-trailers'      
        url += "movies."
        subdomain = true
      end
    end

    url += BASE_URL

    if topic && !subdomain
      url += "/topics/#{topic.slug}"
    end

    url += "/channels"

    if character
      url += "?letter=#{character}"
    end

   url_only ? url : link_to( (character ? character : "Channels"), url) 
  end

  def smart_video_link(video, url_only = false)
    url = "http://"
    subdomain = false

    
      if video.category_id == 7
        url += "tv."
      subdomain = true
      elsif video.category_id == 26
        url += "movies."
        subdomain = true
      end
    
    url += "#{BASE_URL}/#{video.slug}/discuss"

    url_only ? url : link_to(truncate(video.title, :length => 60), url)
  end

  def smart_category_link(category, popular = nil, url_only = false)
    url = "http://"
    subdomain = false
    if category.slug == 'television-shows'
      url += "tv."
      subdomain = true
    elsif category.slug == 'movies-previews-trailers'      
      url += "movies."
      subdomain = true
    end

    url += BASE_URL

    if subdomain
      
    else
      url += "/#{category.slug}"
    end

   
    url_only ? url : link_to(category.name, url)
  end

  def topic_link(url_only = false)
    url = "http://#{BASE_URL}/topics"
    url_only ? url : link_to("Topics", url) 
  end
end
