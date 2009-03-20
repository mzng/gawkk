require 'ftools'

class Util::Thumbnail
  def self.suggest(name, youtube_id)
    if !name.nil?
      Util::Thumbnail.suggest_for_name(name)
    else
      Util::Thumbnail.suggest_for_youtube_id(youtube_id)
    end
  end
  
  def self.suggest_for_name(name = '')
    thumbnail_urls = Array.new
    
    chances = 2
    begin
      chances = chances - 1
      
      # If there weren't any results the first time around, try just using the first two words
      if name.split.size > 2 and chances == 0
        name = name.split.first(2).join(' ')
      end
      
      # Fetch thumbnail suggestions from Truveo
      doc = Hpricot.XML(open("http://xml.truveo.com/apiv3?appid=8ba63637baf8b41fb&method=truveo.videos.getVideos&results=5&query=" + CGI::escape(name)))
      
      (doc/:Video).first(5).each do |video|
        if ((video)/:thumbnailUrl)
          thumbnail_urls << ((video)/:thumbnailUrl).inner_html
        end
      end
      
      # Fetch thumbnail suggestions from YouTube
      client = YouTubeG::Client.new
      client = YouTubeG::Client.new unless client
      if response = client.videos_by(:query => name, :max_results => (5 - thumbnail_urls.size)) and response.videos.size > 0
        response.videos.each do |video|
          thumbnail_urls << video.thumbnails.first.url
        end
      end
      
    end while thumbnail_urls.size == 0 and chances > 0
    
    Util::Thumbnail.write_suggestions(thumbnail_urls)
  end
  
  def self.suggest_for_youtube_id(youtube_id)
    thumbnail_urls = Array.new
    
    # Fetch actual thumbnails from YouTube
    client = YouTubeG::Client.new
    client = YouTubeG::Client.new unless client
    if video = client.video_by(youtube_id)
      video.thumbnails.each do |thumbnail|
        thumbnail_urls << thumbnail
      end
    end
    
    Util::Thumbnail.write_suggestions(thumbnail_urls)
  end
  
  
  def self.use_suggested_thumbnail(video)
    begin
      if !video.thumbnail.blank? and video.thumbnail[/^thumbnails\/suggestions\//]
        File.makedirs "#{RAILS_ROOT}/public/images/thumbnails/" + Time.now.strftime("%Y/%m/%d")
        File.rename(RAILS_ROOT + "/public/images/#{video.thumbnail}", RAILS_ROOT + "/public/images/thumbnails/" + Time.now.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        video.thumbnail = "thumbnails/" + Time.now.strftime("%Y/%m/%d") + "/#{video.slug}.jpg"
      else
        video.thumbnail = ''
      end
    rescue
    end
    
    return video
  end
  
  def self.use_url_thumbnail(video, image_url)
    if !image_url.blank? and Util::Thumbnail.fetch_and_write(image_url, video.slug, video.posted_at)
      video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
    end
  end
  
  
  private
  def self.write_suggestions(thumbnail_urls)
    image_keys = Array.new
    
    thumbnail_urls.each do |thumbnail_url|
      if thumbnail_url.class == YouTubeG::Model::Thumbnail
        thumbnail_url = thumbnail_url.url
      end
      
      hash_key = Digest::SHA1.hexdigest(thumbnail_url)
      image_keys << hash_key

      uri = URI.parse(thumbnail_url)
      Net::HTTP.start(uri.host) { |http|
        resp = http.get(uri.path + (uri.query.nil? ? '' : '?' + uri.query))

        File.makedirs "#{RAILS_ROOT}/public/images/thumbnails/suggestions"
        open("#{RAILS_ROOT}/public/images/thumbnails/suggestions/#{hash_key}.jpg", "wb") { |file|
          file.write(resp.body)
        }

        begin
          image = Magick::Image.read("#{RAILS_ROOT}/public/images/thumbnails/suggestions/#{hash_key}.jpg")
          if image = image[0]
            image.crop_resized!(127, 89)
            image.write("#{RAILS_ROOT}/public/images/thumbnails/suggestions/#{hash_key}.jpg")
            image.destroy!
          end
        rescue
        end
      }
    end
    
    image_keys
  end
  
  def self.fetch_and_write(image_url, slug, timestamp)
    image_fetched = false
    
    uri = URI.parse(image_url)
    Net::HTTP.start(uri.host) { |http|
      resp = http.get(uri.path + (uri.query.nil? ? '' : '?' + uri.query))
      image_fetched = Util::Thumbnail.write(slug, timestamp, resp.body)
    }
    
    image_fetched
  rescue
    return false
  end
  
  def self.write(slug, timestamp, data)
    open("#{RAILS_ROOT}/public/images/thumbnails/" + timestamp.strftime("%Y/%m/%d") + "/#{slug}.jpg", "wb") { |file|
      file.write(data)
    }

    image = Magick::Image.read("#{RAILS_ROOT}/public/images/thumbnails/" + timestamp.strftime("%Y/%m/%d") + "/#{slug}.jpg")
    if image = image[0]
      image.crop_resized!(127, 89)
      image.write("#{RAILS_ROOT}/public/images/thumbnails/" + timestamp.strftime("%Y/%m/%d") + "/#{slug}.jpg")
      image.destroy!
    end
    
    return true
  rescue
    return false
  end
end