xml.instruct! :xml, :version => "1.0" 
xml.rss(:version => "2.0", "xmlns:media" => 'http://search.yahoo.com/mrss/') {
  xml.channel{
    xml.title("#{@user.username} - Activity on Gawkk")
    xml.link("http://www.gawkk.com/#{@user.slug}")
    xml.description("The activity of #{@user.username}")
    xml.language("en-us")
    @news_items.each do |news_item|
      xml.item do
        if news_item.reportable_type == 'Video'
          xml.title(news_item.reportable.name)
          xml.description do
            xml.cdata!(render :partial => "/videos/video_rss.html.erb", :locals => {:news_item => news_item.latest_related, :video => news_item.reportable})
          end
          xml.media(:content, :url => "http://www.gawkk.com/images/#{news_item.reportable.thumbnail.blank? ? 'no-image.png' : news_item.reportable.thumbnail}", :type => "image/jpeg")
          xml.pubDate(news_item.latest_related.created_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
          xml.link("http://www.gawkk.com/#{news_item.latest_related.reportable.slug}/discuss")
          xml.guid("http://www.gawkk.com/#{news_item.latest_related.reportable.slug}/discuss?nid=#{news_item.latest_related.id}")
        elsif news_item.news_item_type.name == 'status'
          xml.title('Status Update')
          xml.description do
            xml.cdata!(render :partial => "/news_items/status_rss.html.erb", :locals => {:news_item => news_item})
          end
          xml.pubDate(news_item.created_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
          xml.link("http://www.gawkk.com/#{@user.slug}/activity")
          xml.guid("http://www.gawkk.com/#{@user.slug}/activity?nid=#{news_item.id}")
        elsif news_item.news_item_type.name == 'add_a_friend'
          xml.title("Now following #{news_item.reportable.username}")
          xml.description do
            xml.cdata!(render :partial => "/news_items/add_a_friend_rss.html.erb", :locals => {:news_item => news_item})
          end
          xml.pubDate(news_item.created_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
          xml.link("http://www.gawkk.com/#{news_item.reportable.slug}/activity")
          xml.guid("http://www.gawkk.com/#{news_item.reportable.slug}/activity?nid=#{news_item.id}")
        elsif news_item.news_item_type.name == 'subscribe_to_channel'
          xml.title("Now following #{news_item.reportable.proper_name}")
          xml.description do
            xml.cdata!(render :partial => "/news_items/subscribe_to_channel_rss.html.erb", :locals => {:news_item => news_item})
          end
          xml.pubDate(news_item.created_at.strftime("%Y-%m-%dT%H:%M%z").insert(-3, ':'))
          xml.link("http://www.gawkk.com/#{news_item.reportable.user.slug}/channel")
          xml.guid("http://www.gawkk.com/#{news_item.reportable.user.slug}/channel?nid=#{news_item.id}")
        end
      end
    end
  }
}