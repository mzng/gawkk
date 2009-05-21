class Util::Avatar
  # Stock
  def self.random
    avatars = Rails.cache.fetch('avatars', :expires_in => 2.weeks) do
      a = Array.new
      
      Dir.new("#{RAILS_ROOT}/public/images/avatars/").each do |filename|
        if filename[filename.size - 4, filename.size - 1] == '.jpg'
          a << "avatars/#{filename}"
        end
      end
      
      a
    end
    
    avatars[rand(avatars.size)]
  end
  
  def self.use_file_avatar(user, file)
    if !file.nil? and Util::Avatar.write("#{user.slug}.jpg", file.read)
      user.update_attribute('thumbnail', "users/#{user.slug}.jpg")
    end
  end
  
  # Third Party
  def self.use_service_avatar(user, service)
    if service and service != 'gawkk' and File.exists?("#{RAILS_ROOT}/public/images/users/#{user.slug}.#{service}.jpg")
      File.rename("#{RAILS_ROOT}/public/images/users/#{user.slug}.#{service}.jpg", "#{RAILS_ROOT}/public/images/users/#{user.slug}.jpg")
      user.update_attribute('thumbnail', "users/#{user.slug}.jpg")
    end
  end
  
  def self.collect_avatars(user)
    avatars = Hash.new
    
    if !user.thumbnail.blank?
      avatars['gawkk'] = "/images/#{user.thumbnail}"
    end
    
    if Util::Avatar.fetch_from_twitter(user)
      avatars['twitter'] = "/images/users/#{user.slug}.twitter.jpg"
      avatars[:default] = 'twitter'
    end
    
    if Util::Avatar.fetch_from_youtube(user)
      avatars['youtube'] = "/images/users/#{user.slug}.youtube.jpg"
      avatars[:default] = 'youtube' if avatars[:default].nil?
    end
    
    if Util::Avatar.fetch_from_friendfeed(user)
      avatars['friendfeed'] = "/images/users/#{user.slug}.friendfeed.jpg"
      avatars[:default] = 'friendfeed' if avatars[:default].nil?
    end
    
    avatars
  end
  
  def self.fetch_from_twitter(user)
    image_fetched = false
    
    begin
      Util::Avatar.delete("#{user.slug}.twitter.jpg")
      
      begin
        if !user.twitter_username.blank?
          client = Util::Twitter.client
          twitter_user = Twitter::User.find(user.twitter_username, client)
          image_url = twitter_user.profile_image_url
          image_url.gsub!(/\_normal\.jpg$/, '.jpg')
          image_fetched = Util::Avatar.fetch_and_write(image_url, "#{user.slug}.twitter.jpg")
        end
      rescue Twitter::RESTError
      end
    rescue
    end
    
    image_fetched
  end
  
  def self.fetch_from_youtube(user)
    image_fetched = false
    
    begin
      Util::Avatar.delete("#{user.slug}.youtube.jpg")
      
      if !user.youtube_username.blank?
        doc = Hpricot(open("http://www.youtube.com/user/#{user.youtube_username}"))
        images = (doc/"div#user-profile-image img")
        
        if images.first and !images.first['src'].blank?
          image_url = images.first['src']
          image_fetched = Util::Avatar.fetch_and_write(image_url, "#{user.slug}.youtube.jpg")
        end
      end
    rescue
    end
    
    image_fetched
  end
  
  def self.fetch_from_friendfeed(user)
    image_fetched = false
    
    begin
      Util::Avatar.delete("#{user.slug}.friendfeed.jpg")
      
      if !user.friendfeed_username.blank?
        doc = Hpricot(open("http://friendfeed.com/#{user.friendfeed_username}"))
        images = (doc/".profile .header .profile img")
        
        if images.first and !images.first['src'].blank?
          image_url = images.first['src']
          image_fetched = Util::Avatar.fetch_and_write(image_url, "#{user.slug}.friendfeed.jpg")
        end
      end
    rescue
    end
    
    image_fetched
  end
  
  def self.fetch_from_facebook(user, image_url)
    image_fetched = false
    
    begin
      Util::Avatar.delete("#{user.slug}.facebook.jpg")
      
      image_fetched = Util::Avatar.fetch_and_write(image_url, "#{user.slug}.facebook.jpg")
    rescue
    end
    
    image_fetched
  end
  
  # Helper Methods
  def self.delete(path)
    if File.exists?("#{RAILS_ROOT}/public/images/users/#{path}")
      File.delete("#{RAILS_ROOT}/public/images/users/#{path}")
    end
  end
  
  def self.fetch_and_write(image_url, path)
    image_fetched = false
    
    uri = URI.parse(image_url)
    Net::HTTP.start(uri.host) { |http|
      resp = http.get(uri.path + (uri.query.nil? ? '' : '?' + uri.query))
      image_fetched = Util::Avatar.write(path, resp.body)
    }
    
    image_fetched
  rescue
    return false
  end
  
  def self.write(path, data)
    open("#{RAILS_ROOT}/public/images/users/#{path}", "wb") { |file|
      file.write(data)
    }

    image = Magick::Image.read("#{RAILS_ROOT}/public/images/users/#{path}")
    if image = image[0]
      image.crop_resized!(75, 75)
      image.write("#{RAILS_ROOT}/public/images/users/#{path}")
      image.destroy!
    end
    
    return true
  rescue
    return false
  end
end