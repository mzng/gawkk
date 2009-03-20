class Util::YouTube
  def self.extract_id(url)
    youtube_id = nil
    
    if url.downcase[/^(http|https):\/\/(.*)?youtube\.com\//] and !url.index('v=', url.index('?') + 1).nil?
      youtube_id = url[/v=[\w-]+/][2, url[/v=[\w-]+/].length]
    end
    
    return youtube_id
  end
end