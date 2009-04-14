require 'ftools'
require 'hpricot'
require 'open-uri'

namespace :joost do
  task :thumbnails => :environment do
    count = 0
    fixed = 0
    urls = Array.new
    
    user = User.find_by_slug('joost')
    channel = Channel.owned_by(user).first
    
    SavedVideo.find(:all, :include => :video, :conditions => ['saved_videos.channel_id = ? AND saved_videos.created_at > ?', channel.id, Time.now - 1.month], :order => 'saved_videos.created_at DESC, saved_videos.id DESC').each do |saved_video|
      video = saved_video.video
      
      if video.thumbnail.blank?
        count = count + 1
        begin
          # Try and grab a thumbnail for this video
          doc = Hpricot.XML(open("http://xml.truveo.com/apiv3?appid=8ba63637baf8b41fb&method=truveo.videos.getVideos&results=1&query=" + CGI::escape(video.title)))
          if (doc/:Video).size > 0 and (((doc/:Video).first)/:thumbnailUrl)
            thumbnail_url = (((doc/:Video).first)/:thumbnailUrl).inner_html
            Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, thumbnail_url)
            video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
            
            fixed = fixed + 1
            urls << "http://gawkk.com/#{video.slug}/discuss"
          end
        rescue
        end
      end
    end
    
    MissingImageDetectionMailer.deliver_log(count, fixed, urls)
  end
end
