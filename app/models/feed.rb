require 'digest/sha1'
require 'open-uri'
require 'feed_tools'

class Feed < ActiveRecord::Base
  belongs_to :category
  belongs_to :owned_by, :class_name => "User", :foreign_key => "owned_by_id"
  
  has_many  :feed_importer_reports, :order => 'created_at DESC', :dependent => :nullify
  has_one   :last_importer_report, :class_name => "FeedImporterReport", :conditions => 'videos_count > 0', :order => 'created_at DESC'
  
  attr_accessor :dont_recategorize
  
  validates_presence_of :category_id, :owned_by_id, :url
  
  def after_save
    Rails.cache.delete(self.cache_key)
    
    if self.dont_recategorize.nil? or self.dont_recategorize == true
      if self.owned_by.feed_owner
        self.owned_by.channels.each do |channel|
          channel.categorize!
        end
      end
    end
  end
  
  def after_create
    if channel = self.owned_by.channels.first
      channel.update_attribute(:search_only, (Feed.count(:all, :conditions => {:owned_by_id => self.owned_by}) == 0))
    end
    
    return true
  end
  
  def after_destroy
    if channel = self.owned_by.channels.first
      channel.update_attribute(:search_only, (Feed.count(:all, :conditions => {:owned_by_id => self.owned_by}) == 0))
    end
    
    return true
  end
  
  def import(word_lists = nil, force = false, thorough = true)
    word_lists = WordList.collect_word_lists if word_lists.nil?
    
    if force or self.feed_importer_reports.size == 0 or (self.feed_importer_reports.first and Time.now > self.feed_importer_reports.first.created_at + self.feed_importer_reports.first.minutes_until_next_fetch.minutes) or (self.feed_importer_reports.first and self.feed_importer_reports.first.thumbnail_count < self.feed_importer_reports.first.videos_count)
      logger.debug "getting ready for #{self.url}"
      report = FeedImporterReport.create :feed_id => self.id

      begin
        logger.debug " parsing"
        
        if self.url.downcase[/^(http|https):\/\/(.*)?hulu\.com\//]
          if self.url.index('?') and self.url.index('enclosures=1').nil?
            self.update_attribute('url', self.url + '&enclosures=1')
          elsif self.url.index('?').nil?
            self.update_attribute('url', self.url + '?enclosures=1')
          end
        end
        
        feed_rss = FeedTools::Feed.open(self.url)

        # total time of (each item.published - item.previous.published) will divide later for average
        total_time_since_previous_item_published = 0
        
        if thorough
          items = feed_rss.items
          logger.debug "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          logger.debug " [thorough]: #{items.size} to process"
          logger.debug "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          
        else # Not thoroughly checking items, allows for faster processing
          oldest_item_to_import = -1
          
          feed_rss.items.each_with_index do |feed_item, i|
            url = Util::Scrub.url(feed_item.link)
            url = Util::Scrub.follow_truveo_url(url)
            
            if (Video.count(:all, :conditions => ['hashed_url = ?', Digest::SHA2.hexdigest(url.nil? ? '' : url)]) == 0) and (DeletedVideo.count(:all, :conditions => ['url = ? OR truveo_url = ?', url, url]) == 0)
              oldest_item_to_import = i
            else
              break
            end
          end
          
          items = (oldest_item_to_import > -1) ? feed_rss.items[0, oldest_item_to_import] : Array.new
          logger.debug "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
          logger.debug "[!thorough]: #{items.size} of #{feed_rss.items.size} to process"
          logger.debug "%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
        end
        
        items.reverse.each_with_index do |feed_item, i|
          logger.debug "  item #{feed_item.title}"
          
          if feed_item.link and (feed_item.title or feed_item.description)
            if i > 0
              if feed_item.time
                total_time_since_previous_item_published += feed_item.time - feed_rss.items.reverse[i - 1].time
              elsif feed_item.published
                total_time_since_previous_item_published += feed_item.published - feed_rss.items.reverse[i - 1].published
              end
            end
            
            url = Util::Scrub.url(feed_item.link)
            url = Util::Scrub.follow_truveo_url(url)
            
            if thorough
              if (Video.count(:all, :conditions => ['hashed_url = ?', Digest::SHA2.hexdigest(url.nil? ? '' : url)]) == 0) and (DeletedVideo.count(:all, :conditions => ['url = ? OR truveo_url = ?', url, url]) == 0)
                video = Feed.import_video(self, feed_item, word_lists, report)
                report.thumbnail_count = report.thumbnail_count + 1 if !video.thumbnail.blank?
              else
                if video = Video.find(:first, :conditions => ['hashed_url = ?', Digest::SHA2.hexdigest(url.nil? ? '' : url)])
                  # If video already exists and we don't have the thumbnail, let's try and get it one more time
                  if video.thumbnail.blank?
                    # Attempt to retrieve thumbnail for this video
                    video = Feed.retrieve_thumbnail(video, feed_item)
                    report.thumbnail_count = report.thumbnail_count + 1 if !video.thumbnail.blank?
                  end
                
                  # If this video is from hulu, generate embed code
                  if video.embed_code.blank?
                    video = Feed.retrieve_embed(video, feed_item)
                  end
                
                  # If the video hasn't been saved by this channel yet, let's save it there also
                  default_channel = Channel.owned_by(self.owned_by).first
                  if SavedVideo.count_by_sql(['SELECT COUNT(*) FROM saved_videos WHERE channel_id = ? AND video_id = ?', default_channel.id, video.id]) == 0
                    saved_video = SavedVideo.create(:channel_id => default_channel.id, :video_id => video.id)
                    
                    ##############################################################
                    # Messaging Layer for SubscriptionMessages has been disabled #
                    ##############################################################
                    # saved_video.generate_messages_for_subscribers!
                  end
                end
              end
            else
              video = Feed.import_video(self, feed_item, word_lists, report)
              report.thumbnail_count = report.thumbnail_count + 1 if !video.thumbnail.blank?
            end
          end
          
          # Ensure we have a thumbnail if we think we have it
          if !video.thumbnail.blank?
            retry_count = 0
            
          #  if Rails.env.production?
          #    begin
          #      open("http://www.gawkk.com/images/#{video.thumbnail}")
          #    rescue OpenURI::HTTPError
          #      if retry_count > 1
          #        ImportMailer.deliver_automatic_shutdown_notification(video)
          #        Parameter.set('feed_importer_status', 'false')
          #      else
          ##        retry_count = retry_count + 1
           #       sleep(3 * retry_count)
           #       retry
           #     end
           #   end
           # end
          end
          
          break if !Parameter.status?('feed_importer_status')
        end

        report.items_in_feed = items.size
        
        if thorough
          if feed_rss.items.size > 1
            report.minutes_until_next_fetch = ((total_time_since_previous_item_published / (feed_rss.items.size - 1)) / 60) * 0.75
          end
          report.minutes_until_next_fetch = 480 if report.minutes_until_next_fetch == 0
        else
          report.minutes_until_next_fetch = 1
        end
        
        report.videos_count = Video.count_by_sql(["SELECT COUNT(*) FROM videos WHERE feed_importer_report_id = ?", report.id])
        report.completed_successfully = true
        report.save
        
        self.update_attribute('last_video_imported_at', report.created_at) if report.videos_count > 0
        
        logger.debug " done"
     # rescue
        # something went wrong, the report's completed_succesffully field will be left as false
     #   deactivate = true
     #   reports = FeedImporterReport.find(:all, :conditions => ['feed_id = ? AND scheduled = false', self.id], :order => 'created_at desc', :limit => 3)
     #   if reports.size == 3
     #     reports.each do |report|
     #       deactivate = false if report.completed_successfully?
     #     end
     #     
     #     if deactivate
     #       self.update_attribute('active', false)
     #     end
     #   end
      end
      
      return report
    else
      return nil
    end
  end
  
  def self.import_video(feed, feed_item, word_lists, report = nil)
    url = Util::Scrub.url(feed_item.link)
    url = Util::Scrub.follow_truveo_url(url)
    
    # Strip 'Video: ' prefix from feed_item.title, if present
    if !feed_item.title.nil? and feed_item.title.length > 7 and feed_item.title[/^Video: /]
      feed_item.title = feed_item.title[7, feed_item.title.length]
    end
    
    video = Video.new
    video.category_id   = feed.category.id
    video.name          = Util::Scrub.html(feed_item.title ? feed_item.title : Util::Scrub.html(feed_item.description ? (feed_item.description.length > 50 ? feed_item.description.first(50) : feed_item.description) : '', ''), '')
    video.description   = Util::Scrub.html(feed_item.description ? feed_item.description : video.name, '')
    video.url           = url
    video.posted_by_id  = feed.owned_by.id
    video.feed_importer_report_id = report.id if report
  
    # do i need this?
    video.name ||= ''
    video.description ||= ''
  
    # compare all words from video.name and video.description to the Porn Words list - if any matches, recategorize
    foreign = false
    words = (video.name.split + video.description.split)
    words.each do |word|
      if word_lists['Spanish'][word.downcase]
        foreign = true
      elsif word_lists['Porn Words'][word.downcase]
        video.category_id = Category.find_by_slug('sexy-time').id
        logger.debug "recategorized #{video.slug} to 'sexy-time' because of '#{word}'"
      end
    end
  
    if !foreign
      begin
        if video.save
          saved_video = SavedVideo.create(:channel_id => Channel.owned_by(feed.owned_by).first.id, :video_id => video.id)
          
          ##############################################################
          # Messaging Layer for SubscriptionMessages has been disabled #
          ##############################################################
          # saved_video.generate_messages_for_subscribers!

          # Hack for non auto-incrementing saves_count cache on video import
          video.reload
          video.update_attribute('saves_count', 1) if video.saves_count == 0
          
          # If this video has a truveo url, let's grab the underlying source url
          video.retrieve_truveo_redirect

          # Attempt to retrieve thumbnail for this video
          video = Feed.retrieve_thumbnail(video, feed_item)
          
          # Attempt to generate embed code for this video
          video = Feed.retrieve_embed(video, feed_item)
          
          # video.cache!
        end
      rescue
        # to prevent from byte encoding error
      end
      
      return video
    else
      return nil
    end
  end
  
  def self.import(keep_fresh = false, check_request_queue = false)
    Parameter.set('feed_importer_status', 'true')
    Rails.cache.write("feed-importer:status", 'true', :expires_in => 2.weeks)
    
    import_request = nil
    word_lists = WordList.collect_word_lists
    
    while feed = Feed.find(:first, :include => :owned_by, :conditions => ["#{keep_fresh ? 'keep_fresh = true AND ': ''}active = true AND locked = false AND users.feed_owner = true"], :order => keep_fresh ? 'last_accessed_at ASC' : 'rand()')
      
      begin
        feed.last_accessed_at = Time.now
        feed.locked = true
        feed.save
        feed.import(word_lists, keep_fresh)
     # rescue
        # handled inside feed.import
      ensure
        feed.channel_videos_count = Video.count(:all, :joins => 'LEFT JOIN feed_importer_reports ON videos.feed_importer_report_id = feed_importer_reports.id', :conditions => ['feed_importer_reports.feed_id = ?', feed.id])
        feed.locked = false
        feed.save
      end
      
      if Feed.count(:all, :conditions => ['locked = true']) > Feed.number_of_feed_importers
        Feed.update_all('locked = false', ['locked = true AND last_accessed_at < ?', Time.now - 2.hours])
      end
      
      break if !Parameter.status?('feed_importer_status')
    end
  end
  
  def self.schedule
    feeds = Feed.find(:all, :include => :owned_by, :conditions => ["active = true AND users.feed_owner = true"])
    feeds.each do |feed|
      report = feed.feed_importer_reports.find(:first)
      if !report or ((Time.now - report.created_at) > 72.hours and rand(10) > 4) or ((Time.now - report.created_at) > 48.hours and rand(10) > 6) or ((Time.now - report.created_at) > 24.hours and rand(10) > 8)
        FeedImporterReport.create :feed_id => feed.id, :minutes_until_next_fetch => 0, :completed_successfully => true, :scheduled => true
      end
    end
  end
  
  # Utility Methods
  def self.retrieve_thumbnail(video, feed_item)
    # Attempt to retrieve thumbnail image from rss feed
    begin
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/(.*)?youtube\.com\//]
        if !video.url.index('v=', video.url.index('?') + 1).nil?
          id = video.url[/v=[\w-]+/][2, video.url[/v=[\w-]+/].length]
          thumbnail_url = "http://img.youtube.com/vi/#{id}/#{(rand(3) + 1).to_s}.jpg"
          
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, thumbnail_url)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/feeds\.digg\.com\/~r\/digg\/videos\/popular/]
        media_thumbnails = feed_item.find_all_nodes('media:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.attributes['url']
          thumbnail_url = media_thumbnails.first.attributes['url']
          thumbnail_url.gsub!(/t\.jpg$/, 'l.jpg')
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, thumbnail_url)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank? and !feed_item.media_thumbnail_link.blank? and !feed_item.media_thumbnail_link.downcase[/^(http|https):\/\/serve\.castfire\.com\//]
        thumbnail_link = feed_item.media_thumbnail_link
        if thumbnail_link != 'http://www.todaysbigthing.com/'
          if thumbnail_link[/^http:\/\/www\.todaysbigthing\.com\//]
            thumbnail_link.gsub!(/http:\/\/www\.todaysbigthing\.com\//, '')
          end
          
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, thumbnail_link)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end

      if video.thumbnail.blank?
        media_thumbnails = feed_item.find_all_nodes('media:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.attributes['url']
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.attributes['url'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank?
        media_thumbnails = feed_item.find_all_nodes('mediathumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.attributes['url']
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.attributes['url'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/video\.yahoo\.com\//]
        media_thumbnails = feed_item.find_all_nodes('media:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.get_text
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/(.*)?joost\.com\//]
        media_thumbnails = feed_item.find_all_nodes('joost:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.get_text
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # msnbc videos
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/www\.msnbc\.msn\.com\//]
        media_content = feed_item.find_all_nodes('media:content')
        if media_content and media_content.first and media_content.first.attributes['url']
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_content.first.attributes['url'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank?
        media_thumbnails = feed_item.find_all_nodes('media:content/media:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.attributes['url']
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.attributes['url'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end

      if video.thumbnail.blank?
        media_thumbnails = feed_item.find_all_nodes('media:group/media:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.attributes['url']
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.attributes['url'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank?
        media_content = feed_item.find_all_nodes('media:group/media:content')
        if media_content and media_content.size > 0
          media_content.each do |m|
            if m.attributes['type'] and m.attributes['type'] == 'image/jpeg'
              Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, m.attributes['url'])
              video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
            end
          end
        end
      end

      if video.thumbnail.blank?
        media_thumbnails = feed_item.find_all_nodes('media:group/media:content/media:thumbnail')
        if media_thumbnails and media_thumbnails.first and media_thumbnails.first.attributes['url']
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.attributes['url'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      if video.thumbnail.blank? and !video.url.downcase[/^(http|https):\/\/video\.google\.([a-z]*)\//] and feed_item.find_all_nodes('enclosure').size > 0 and feed_item.enclosures and feed_item.enclosures.size > 0
        url = feed_item.enclosures.first.href
        if url.downcase[/(jpg|gif|tif|png|bmp)$/]
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, url)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end

      if video.thumbnail.blank? and Util::Thumbnail.able_to_fetch?(video.url) and Util::Thumbnail.fetch(video.posted_at, video.slug, video.url)
        video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
      end

      if video.thumbnail.blank? and Util::Thumbnail.fetch(video.posted_at, video.slug, video.url, feed_item.description)
        video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
      end
      
      # thenewsroom.com uses custom namespaces
      if video.thumbnail.blank?
        tnr_preview_images = feed_item.find_all_nodes('tnr:previewImage')
        if tnr_preview_images and tnr_preview_images.first and tnr_preview_images.first.get_text and !tnr_preview_images.first.get_text.blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, tnr_preview_images.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end

      # The Daily Show uses custom namespaces
      if video.thumbnail.blank?
        m1image_urls = feed_item.find_all_nodes('m1Image/url')
        if m1image_urls and m1image_urls.first and m1image_urls.first.get_text and !m1image_urls.first.get_text.blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, m1image_urls.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end

      # nfl.com uses custom namespaces
      if video.thumbnail.blank?
        nfl_images = feed_item.find_all_nodes('nfl:image')
        if nfl_images and nfl_images.first and nfl_images.first.get_text and !nfl_images.first.get_text.blank?
          begin
            url = nfl_images.first.get_text.to_s
            url = url[0, url.index('video_') + 6] + 'cp.jpg'
            Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, url)
            video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
          rescue
          end
        end
      end
      
      # gametrailers.com uses custom namespaces
      if video.thumbnail.blank?
        exInfo_images = feed_item.find_all_nodes('exInfo:image')
        if exInfo_images and exInfo_images.first and exInfo_images.first.get_text and !exInfo_images.first.get_text.blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, exInfo_images.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # cartoonnetwork.com uses custom namespaces
      if video.thumbnail.blank?
        cn_images = feed_item.find_all_nodes('cn:thumbnail')
        if cn_images and cn_images.first and cn_images.first.get_text and !cn_images.first.get_text.blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, cn_images.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # liveleak.com uses custom elements
      if video.thumbnail.blank?
        thumb_locations = feed_item.find_all_nodes('thumb_location')
        if thumb_locations and thumb_locations.first and thumb_locations.first.get_text and !thumb_locations.first.get_text.blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, thumb_locations.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # videojug.com, thedailytube, cnbc, kyte.tv, veoh, video.236.com, onnetworks, wsjonline.com and videosift.com has images in the html descriptions
      if video.thumbnail.blank? and (video.url.downcase[/^(http|https):\/\/(.*)?joost\.com\//] or video.url.downcase[/^(http|https):\/\/nbcsports\.msnbc\.com\//] or video.url.downcase[/^(http|https):\/\/(.*)?videojug\.com\//] or video.url.downcase[/^(http|https):\/\/(.*)?thedailytube\.com\//] or video.url.downcase[/^(http|https):\/\/(.*)?cnbc\.com\//] or video.url.downcase[/^(http|https):\/\/(.*)?kyte\.tv\//] or video.url.downcase[/^(http|https):\/\/(.*)?veoh\.com\//] or video.url.downcase[/^(http|https):\/\/video\.236\.com\//] or video.url.downcase[/^(http|https):\/\/(.*)?\.onnetworks\.com\//] or video.url.downcase[/^(http|https):\/\/feeds\.wsjonline\.com\//] or video.url.downcase[/^(http|https):\/\/(.*)?\.ustream\.tv\//] or video.url.downcase[/^(http|https):\/\/(.*)?snotr\.com\//] or video.url.downcase[/^(http|https):\/\/videos\.onsmash\.com\//] or video.url.downcase[/^(http|https):\/\/link\.brightcove\.com\/services\/link\/bcpid988327350\//] or video.url.downcase[/^(http|https):\/\/(.*)?videosift\.com\//])
        desc = Hpricot(feed_item.description)
        if desc.at('img') and desc.at('img')['src'] and !desc.at('img')['src'].blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, desc.at('img')['src'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # sxswvideo has images in the html encoded content descriptions
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/feeds\.feedburner\.com\/%7er\/sxswvideo/]
        desc = Hpricot(feed_item.content)
        if desc.at('img') and desc.at('img')['src'] and !desc.at('img')['src'].blank?
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, desc.at('img')['src'])
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # go211.com users custom elements
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/(.*)?go211\.com\//]
        media_thumbnails = feed_item.find_all_nodes('image/url')
        if media_thumbnails and media_thumbnails.first
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, media_thumbnails.first.get_text.to_s)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # video.msn.com uses enclosures
      if video.thumbnail.blank? and video.url.downcase[/^(http|https):\/\/video\.msn\.com\//]
        enclosures = feed_item.enclosures
        if enclosures and enclosures.first and enclosures.first.type == 'image/jpeg'
          Util::Thumbnail.fetch_from_url(video.posted_at, video.slug, enclosures.first.href)
          video.update_attribute('thumbnail', "thumbnails/" + video.posted_at.strftime("%Y/%m/%d") + "/#{video.slug}.jpg")
        end
      end
      
      # generate embed code for break.com
      if video.url.downcase[/^(http|https):\/\/(.*)?break\.com\//]
        embeds = feed_item.find_all_nodes('embed')
        if embeds and embeds.first
          embed_link = embeds.first.get_text.to_s
          video.update_attribute('embed_code', "<object width=\"464\" height=\"392\"><param name=\"movie\" value=\"#{embed_link}\"></param><embed src=\"#{embed_link}\" type=\"application/x-shockwave-flash\" width=\"464\" height=\"392\"></embed></object>")
        end
      end
    rescue
      # something went wrong, so we don't have a thumbnail
    ensure
      return video
    end
  end
  
  def self.retrieve_embed(video, feed_item)
    begin
      if video.url.downcase[/^(http|https):\/\/(.*)?hulu\.com\//]
        if feed_item.enclosures and feed_item.enclosures.first and feed_item.enclosures.first.type == 'application/x-shockwave-flash'
          video.swf_url = feed_item.enclosures.first.href
          video.embed_code = "<object width=\"630\" height=\"365\"><param name=\"movie\" value=\"#{video.swf_url}\"></param><embed src=\"#{video.swf_url}\" type=\"application/x-shockwave-flash\"  width=\"630\" height=\"365\"></embed></object>"
          video.save
        end
      elsif video.url.downcase[/^(http|https):\/\/feeds\.reuters\.com\//]
        if feed_item.find_all_nodes('feedburner:origLink') and feed_item.find_all_nodes('feedburner:origLink').first
          url = feed_item.find_all_nodes('feedburner:origLink').first.get_text.to_s
          video_id = url[url.index('videoId=') + 8, url[url.index('videoId=') + 8, url.length].index('&')]
          video.embed_code = "<object type=\"application/x-shockwave-flash\" data=\"http://static.reuters.com/resources/flash/include_video.swf?edition=US&videoId=#{video_id}\" width=\"422\" height=\"346\"><param name=\"wmode\" value=\"transparent\" /><param name=\"movie\" value=\"http://www.reuters.com/resources/flash/include_video.swf?edition=US&videoId=#{video_id}\" /><embed src=\"http://www.reuters.com/resources/flash/include_video.swf?edition=US&videoId=#{video_id}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"422\" height=\"346\"></embed></object>"
          video.save
        end
      elsif video.url.downcase[/^(http|https):\/\/feedproxy\.google\.com\/(.*)collegehumor/]
        if feed_item.find_all_nodes('feedburner:origLink') and feed_item.find_all_nodes('feedburner:origLink').first
          url = feed_item.find_all_nodes('feedburner:origLink').first.get_text.to_s
          video_id = url[/video:\d+/][6, url[/video:\d+/].length]
          video.embed_code = "<object type=\"application/x-shockwave-flash\" data=\"http://www.collegehumor.com/moogaloop/moogaloop.swf?clip_id=#{video_id}&fullscreen=1\" width=\"480\" height=\"360\" ><param name=\"allowfullscreen\" value=\"true\"/><param name=\"wmode\" value=\"transparent\"/><param name=\"AllowScriptAccess\" value=\"true\"/><param name=\"movie\" quality=\"best\" value=\"http://www.collegehumor.com/moogaloop/moogaloop.swf?clip_id=#{video_id}&fullscreen=1\"/><embed src=\"http://www.collegehumor.com/moogaloop/moogaloop.swf?clip_id=#{video_id}&fullscreen=1\" type=\"application/x-shockwave-flash\" wmode=\"transparent\"  width=\"480\" height=\"360\"  allowScriptAccess=\"always\"></embed></object>"
          video.save
        end
      elsif video.url.downcase[/^(http|https):\/\/(.*)?liveleak\.com\//]
        if feed_item.find_all_nodes('embed_url') and feed_item.find_all_nodes('embed_url').first
          url = feed_item.find_all_nodes('embed_url').first.get_text.to_s
          video.embed_code = "<object width=\"450\" height=\"370\"><param name=\"movie\" value=\"#{url}\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"#{url}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"450\" height=\"370\"></embed></object>"
          video.save
        end
      elsif video.url.downcase[/^(http|https):\/\/(.*)?webbalert\.com\//]
        desc = Hpricot(feed_item.description)
        video.embed_code = desc.at('object').to_html
        video.save
      elsif video.url.downcase[/^(http|https):\/\/tv\.boingboing\.net/]
        desc = Hpricot(feed_item.description)
        video.embed_code = desc.at('object').to_html
        video.save
      elsif video.url.downcase[/^(http|https):\/\/(.*)?snotr\.com/]
        if video.url.index('video/')
          video_id = video.url[/video\/\d+/][6, video.url[/video\/\d+/].length]
          video.embed_code = "<iframe src=\"http://www.snotr.com/embed/#{video_id}\" width=\"400\" height=\"330\" frameborder=\"0\"></iframe>"
          video.save
        end
      elsif video.url.downcase[/^(http|https):\/\/(.*)?onsmash\.com/]
        if video.url.index('/v/')
          video_id = video.url[/\/v\/\w+/][3, video.url[/\/v\/\w+/].length]
          video.embed_code = "<object width=\"448\" height=\"374\"><param name=\"movie\" value=\"http://videos.onsmash.com/e/#{video_id}\"></param><param name=\"allowFullscreen\" value=\"true\"><param name=\"allowScriptAccess\" value=\"always\"></param><param name=\"allowNetworking\" value=\"all\"></param><embed src=\"http://videos.onsmash.com/e/#{video_id}\" type=\"application/x-shockwave-flash\" allowFullScreen=\"true\" allowNetworking=\"all\" allowScriptAccess=\"always\" width=\"448\" height=\"374\"></embed></object>"
          video.save
        end
      end
    rescue
      # something went wrong, so we don't have the embed code
    ensure
      return video
    end
  end
  
  def generate_embed_code_from_swf_url(video, feed_item)
    # Attempt to retrieve swf url from rss feed
    begin
      if video.embed_code.blank? and feed_item.find_all_nodes('enclosure').size > 0 and feed_item.enclosures and feed_item.enclosures.size > 0
        feed_item.enclosures.each do |enclosure|
          if enclosure.type == 'application/x-shockwave-flash'
            video.swf_url = enclosure.href
            video.embed_code = "<object class=\"from-rss-enclosure\" width=\"500\" height=\"415\"><param name=\"movie\" value=\"#{video.swf_url}\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"#{video.swf_url}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"500\" height=\"415\"></embed></object>"
            video.save
          
            report.embed_code_from_rss = true
          end
        end
      end
    
      if video.embed_code.blank? and video.url and !video.url.downcase[/^(http|https):\/\/xml\.truveo\.com\//]
        media_content_nodes = feed_item.find_all_nodes('media:content')
        if media_content_nodes and media_content_nodes.first and media_content_nodes.first.attributes['url'] and media_content_nodes.first.attributes['medium'] == 'video'
          video.swf_url = media_content_nodes.first.attributes['url']
          video.embed_code = "<object class=\"from-rss-media-content\" width=\"500\" height=\"415\"><param name=\"movie\" value=\"#{video.swf_url}\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"#{video.swf_url}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"500\" height=\"415\"></embed></object>"
          video.save
        
          report.embed_code_from_rss = true
        end
      end
    
      if (video.url.downcase[/^(http|https):\/\/video\.google\.([a-z]*)\//] or video.embed_code.blank?) and video.url and !video.url.downcase[/^(http|https):\/\/xml\.truveo\.com\//]
        media_content_nodes = feed_item.find_all_nodes('media:group/media:content')
        if media_content_nodes and media_content_nodes.first and media_content_nodes.first.attributes['url'] and media_content_nodes.first.attributes['medium'] == 'video'
          video.swf_url = media_content_nodes.first.attributes['url']
          video.embed_code = "<object class=\"from-rss-media-content\" width=\"500\" height=\"415\"><param name=\"movie\" value=\"#{video.swf_url}\"></param><param name=\"wmode\" value=\"transparent\"></param><embed src=\"#{video.swf_url}\" type=\"application/x-shockwave-flash\" wmode=\"transparent\" width=\"500\" height=\"415\"></embed></object>"
          video.save
        
          report.embed_code_from_rss = true
        end
      end
    rescue
      # something went wrong, we couldn't get the swf url
    end
  end
  
  def self.number_of_feed_importers
    Parameter.find_by_name('number_of_regular_feed_importers').value.to_i + Parameter.find_by_name('number_of_fresh_feed_importers').value.to_i
  end
end
