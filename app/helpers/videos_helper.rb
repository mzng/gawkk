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
end
