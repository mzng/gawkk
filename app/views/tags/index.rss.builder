xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", "xmlns:media" => 'http://search.yahoo.com/mrss/') {
  xml.channel{
    xml.title("Gawkk - #{@q} Videos")
    xml.link("http://www.gawkk.com/tags/#{@q}")
    xml.language("en-us")
    @videos.each do |video|
      xml.item do
        xml.title(video.name)
        xml.description do
          xml.cdata!(render :partial => "/videos/video_rss.html.erb", :locals => {:video => video})
        end
        xml.media(:content, :url => "http://www.gawkk.com/images/#{video.thumbnail.blank? ? 'no-image.png' : video.thumbnail}", :type => "image/jpeg")
        xml.pubDate(video.posted_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
        xml.link("http://www.gawkk.com/#{video.slug}/discuss")
        xml.guid("http://www.gawkk.com/#{video.slug}/discuss")
      end
    end
  }
}