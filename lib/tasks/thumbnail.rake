require 'ftools'
require 'hpricot'
require 'open-uri'

namespace :thumbnail do
  task :fixer => :environment do
    count = 0
    fixed = 0
    urls = Array.new
    
    for page in (1..(Video.count(:all, :conditions => ['posted_at > ? AND thumbnail != ?', (Time.now - 27.hours), '']) / 100 + 1)).to_a
      Video.find(:all, :conditions => ['posted_at > ? AND thumbnail != ?', (Time.now - 27.hours), ''], :order => 'posted_at DESC', :limit => 100, :offset => (100 * (page - 1))).each do |video|
        if !video.thumbnail.blank? and !File.exists?("#{RAILS_ROOT}/public/images/#{video.thumbnail}")
          # Reset the thumbnail path
          video.update_attribute('thumbnail', '')
          
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
    end
    
    MissingImageDetectionMailer.deliver_log(count, fixed, urls)
  end
end
