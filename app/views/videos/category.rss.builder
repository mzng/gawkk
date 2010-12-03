xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", "xmlns:media" => 'http://search.yahoo.com/mrss/') {
  xml.channel{
    xml.title("Gawkk - #{@category.name} Category - #{@popular ? 'Popular' : 'Newest'} Videos")
    xml.link("http://www.gawkk.com")
    xml.description("Share Videos with Friends")
    xml.language("en-us")
    @videos.each do |video|
      xml.item do
        xml.title(video.name)
        xml.description do
          xml.cdata!(render :partial => "/videos/video_rss.html.erb", :locals => {:video => video})
        end
        xml.media(:content, :url => "http://www.gawkk.com/images/#{video.thumbnail.blank? ? 'no-image.png' : video.thumbnail}", :type => "image/jpeg")
        xml.pubDate(@popular ? video.promoted_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':') : video.posted_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
        xml.link(smart_video_link(video, true))
        xml.guid(smart_video_link(video, true))
      end
    end
  }
}
