xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0"){
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
        xml.thumbnail("http://www.gawkk.com/images/#{video.thumbnail.blank? ? 'no-image.png' : video.thumbnail}")
        xml.pubDate(@popular ? video.promoted_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':') : video.posted_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
        xml.link("http://www.gawkk.com/#{video.slug}/discuss")
        xml.guid("http://www.gawkk.com/#{video.slug}/discuss")
      end
    end
  }
}