require 'youtube_g'
class Util::YouTube
  def self.client
    client = YouTubeG::Client.new
    client = YouTubeG::Client.new unless client
    
    return client
  end
  
  def self.extract_id(url)
    youtube_id = nil
    
    if url.downcase[/^(http|https):\/\/(.*)?youtube\.com\//] and !url.index('v=', url.index('?') + 1).nil?
      youtube_id = url[/v=[\w-]+/][2, url[/v=[\w-]+/].length]
    end
    
    return youtube_id
  end
  
  def self.thumbnail_url(result)
    if result.thumbnails.size > 0
      result.thumbnails.first.url
    else
      '/images/no-image.png'
    end
  end
end
