require 'subdomain-fu'
module VideosHelper
  def intelligent_author_avatar(author)
    image = image_tag(author.thumbnail.blank? ? 'profile-pic.jpg' : author.thumbnail, :class => 'avatar')
    if author.feed_owner?
      link_to image, user_channel_path(author)
    else
      image
    end
  end

  def intelligent_author_name(author)
    if author.feed_owner?
      link_to author.username, user_channel_path(author)
    else
      author.username
    end
  end

  def smart_category_link(category)
    base_domain = request.domain
    base_domain += ":#{request.port}" if request.port

    base_domain.gsub!(/tv\.|www\./, '')


    if category.slug == "television-shows"
      return "http://tv.#{base_domain}"
    else
      return "http://#{base_domain}#{category_path(category)}"
    end
  end
end
