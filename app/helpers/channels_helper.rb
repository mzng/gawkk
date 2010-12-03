module ChannelsHelper
  def crumbs_for_channel_browsing(topic = nil, letter = nil)
    parts = []

    if topic
      parts << {:name => 'Topics', :params => topic_link(true) }
      parts << {:name => topic.name, :params => smart_category_link(topic, false, true)} 
    end

    parts <<  {:name => "Channels", :params => smart_channel_topic_link(topic, nil, true)}

    if letter
      if letter == '0'
        parts << {:name => "#", :params => smart_channel_topic_link(topic, letter, true)}
      else
        parts << {:name => letter, :params => smart_channel_topic_link(topic, letter, true)}
      end
    end
    parts
  end
end
