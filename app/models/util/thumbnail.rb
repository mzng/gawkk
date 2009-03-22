require 'ftools'
require 'net/http'
require 'open-uri'

class Util::Thumbnail
  # Thumbnail Fetching
  def self.able_to_fetch?(url)
    url = '' if url.nil?
    
    if url.downcase[/^(http|https):\/\/(.*)?youtube\.com\//] # *.youtube.com
      return true
    elsif url.downcase[/^(http|https):\/\/(.*)?ifilm\.com\//] # *.ifilm.com
      return true
    elsif url.downcase[/^(http|https):\/\/(.*)?spike\.com\//] # *.spike.com
      return true
    elsif url.downcase[/^(http|https):\/\/(.*)?revision3\.com\//] # *.revision3.com
      return true
    else
      return false
    end
  end
  
  def self.fetch(posted_at, slug, url, description = nil, image_url = nil)
    if url.downcase[/^(http|https):\/\/(.*)?youtube\.com\//] # *.youtube.com
      return false if url.index('v=', url.index('?') + 1).nil?
      id = url[/v=[\w-]+/][2, url[/v=[\w-]+/].length]
      
      Net::HTTP.start("img.youtube.com") { |http|
        resp = http.get("/vi/#{id}/#{(rand(3) + 1).to_s}.jpg")
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    elsif url.downcase[/^(http|https):\/\/(.*)?ifilm\.com\//] # *.ifilm.com
      return false if url.index('/video/').nil?
      id = url[/\/video\/\d+/][7, url[/\/video\/\d+/].length]
      
      Net::HTTP.start("img#{(rand(4) + 1).to_s}.ifilmpro.com") { |http|
        resp = http.get("/resize/image/stills/films/resize/istd/#{id}.jpg?width=130")
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    elsif url.downcase[/^(http|https):\/\/(.*)?spike\.com\//] # *.spike.com
      if !url.index('/video/').nil?
        id = nil
        if url[/\/video\/\d+/]
          id = url[/\/video\/\d+/][7, url[/\/video\/\d+/].length]
        else
          id = url[/\/video\/[\w-]+\/\d+/][url[/\/video\/[\w-]+\//].length, url[/\/video\/[\w-]+\/\d+/].length]
        end
        
        if id
          Net::HTTP.start("img#{(rand(4) + 1).to_s}.ifilmpro.com") { |http|
            resp = http.get("/resize/image/stills/films/resize/istd/#{id}.jpg?width=130")
            Util::Thumbnail.write(slug, posted_at, resp.body)
          }
          return true
        else
          return false
        end
      elsif !url.index('/episode/').nil?
        id = url[/\/episode\/\d+/][9, url[/\/episode\/\d+/].length]

        Net::HTTP.start("img#{(rand(4) + 1).to_s}.ifilmpro.com") { |http|
          resp = http.get("/resize/image/stills/films/resize/istd/#{id}.jpg?width=130")
          Util::Thumbnail.write(slug, posted_at, resp.body)
        }
        return true
      else
        return false
      end
    
    elsif url.downcase[/^(http|https):\/\/(.*)?revision3\.com\//] # *.revision3.com
      url = URI.parse(url)
      Net::HTTP.start(url.host) { |http|
        resp = http.get("/static/images/shows/#{url.path}/screenshot.jpg")
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from mojoflix from feed item
    elsif url.downcase[/^(http|https):\/\/(.*)?break\.com\//] and !image_url.nil? # *.break.com
      url = URI.parse(image_url)
      Net::HTTP.start(url.host) { |http|
        resp = http.get(url.path)
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from mojoflix from feed item descriptions
    # uses rss 2.0 and media:thumbnail tag
    elsif url.downcase[/^(http|https):\/\/(.*)?mojoflix\.com\//] and !description.nil? # *.mojoflix.com
      return false if url.index('/Video/').nil?
      id = url[/\/Video\/[\w-]+/][7, url[/\/Video\/[\w-]+/].length]
      
		  resp = Net::HTTP.get_response('files.mojoflix.com', description[/files\.mojoflix\.com\/(.*)border/][18, description[/files\.mojoflix\.com\/(.*)border/].length - 26])
      next_resp = Net::HTTP.get(URI.parse(resp['location']))
      Util::Thumbnail.write(slug, posted_at, next_resp)
      
      return true
    
    # can only get thumbnails from vidilife from feed item descriptions
    # uses rss 2.0 and media:thumbnail tag
    elsif url.downcase[/^(http|htps):\/\/(.*)?vidilife\.com\//] and !description.nil? # *.vidilife.com
      return false if url.index('/video_play').nil?
      
      Net::HTTP.start("media.vidilife.com") { |http|
        resp = http.get(description[/media\.vidilife\.com\/(.*)align=\"right\" border=\"0\" width=\"120\"/][18, description[/media\.vidilife\.com\/(.*)align=\"right\" border=\"0\" width=\"120\"/].length - 56])
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from daily motion from feed item description
    # uses rss 2.0 and media:thumbnail tag
    elsif url.downcase[/^(http|htps):\/\/(.*)?dailymotion\.com\//] and !description.nil? # *.dailymotion.com
      url = URI.parse(description[/src="(.*)style=/][5, description[/src="(.*)style=/].length - 13])
      Net::HTTP.start(url.host) { |http|
        resp = http.get(url.path)
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from stupidvideos from feed item descriptions
    elsif url.downcase[/^(http|htps):\/\/(.*)?stupidvideos\.com\//] and !image_url.nil? # *.stupidvideos.com
      url = URI.parse(image_url)
      Net::HTTP.start(url.host) { |http|
        resp = http.get(url.path)
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from heavy from feed item descriptions
    # uses rss 2.0 and media:thumbnail tag
    elsif url.downcase[/^(http|htps):\/\/(.*)?heavy\.com\//] and !description.nil? # *.heavy.com
      url = URI.parse(description[/src="(.*)alt=/][5, description[/src="(.*)alt=/].length - 11])
      Net::HTTP.start(url.host) { |http|
        resp = http.get(url.path)
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from tmz/brightcove from feed item descriptions
    elsif url.downcase[/^(http|htps):\/\/(.*)?brightcove\.com\//] and !description.nil? # *.brightcove.com
      url = URI.parse(description[/src="(.*)\//][5, description[/src="(.*)\//].length - 7])
      Net::HTTP.start(url.host) { |http|
        resp = http.get(url.path)
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
    
    # can only get thumbnails from livevideo from feed item descriptions
    elsif url.downcase[/^(http|htps):\/\/(.*)?livevideo\.com\//] and !description.nil? # *.livevideo.com
      url = URI.parse(description[/src="(.*)align=right/][5, description[/src="(.*)align=right/].length - 18])
      Net::HTTP.start(url.host) { |http|
        resp = http.get(url.path)
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
      return true
  
    else
      return false
    end
  end
  
  def self.fetch_from_url(posted_at, slug, url)
    if url.downcase[/^(http|https):\/\/(.*)?mojoflix\.com\//] or url.downcase[/^(http|https):\/\/serve\.castfire\.com\//] # to handle mojoflix and graphingsocial image url redirects
      uri = URI.parse(url)
      resp = Net::HTTP.get(URI.parse(Net::HTTP.get_response(uri.host, uri.path)['location']))
      Util::Thumbnail.write(slug, posted_at, resp)
    elsif url.downcase[/^(http|https):\/\/(.*)?crackle\.com\/video\//] # to handle crackle image url redirects
      uri = URI.parse(url)
      resp = Net::HTTP.get(URI.parse(Net::HTTP.get_response(uri.host, uri.path + (uri.query.nil? ? '' : '?' + uri.query))['location']))
      Util::Thumbnail.write(slug, posted_at, resp)
    elsif url.downcase[/^(http|https):\/\/media\.webbalert\.com\/video\//] # to handle webbalert image url redirects
      begin
        url = url[0, url.length - 8] + '.jpg' if url[url.length - 8, url.length] == '.tmb.jpg'
      rescue
      end
      
      uri = URI.parse(url)
      resp = Net::HTTP.get(URI.parse(Net::HTTP.get_response(uri.host, uri.path)['location']))
      Util::Thumbnail.write(slug, posted_at, resp)
    else
      uri = URI.parse(url)
      Net::HTTP.start(uri.host) { |http|
        resp = http.get(uri.path + (uri.query.nil? ? '' : '?' + uri.query))
        Util::Thumbnail.write(slug, posted_at, resp.body)
      }
    end
  end
  
  
  # Thumbnail Suggestions
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
  # Utility Methods
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
    File.makedirs "#{RAILS_ROOT}/public/images/thumbnails/" + timestamp.strftime("%Y/%m/%d")
    
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