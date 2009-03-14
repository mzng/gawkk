require 'memcache_util'

class DeleteVideosAndUpdateCategoriesAndChannels < ActiveRecord::Migration
  def self.up
    # ActiveRecord::Base.transaction do
      Video.find(:all, :conditions => 'deleted = true').each do |video|
        say video.slug
        DeletedVideo.create :name => video.name, :url => video.url, :truveo_url => video.truveo_url, :deleted_at => Time.now
        video.destroy
      end
      
      Category.find(:all, :order => 'position').each do |category|
        say category.slug
        category.earliest_popular_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NOT NULL', category.id], :order => 'promoted_at ASC')
        category.earliest_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NULL', category.id], :order => 'posted_at ASC')
        category.latest_popular_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NOT NULL', category.id], :order => 'promoted_at DESC')
        category.latest_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NULL', category.id], :order => 'posted_at DESC')
        category.save
      end
      
      Channel.reset_column_information
      Channel.find(:all, :order => 'name').each do |channel|
        say channel.name
        if save = Save.find(:first, :conditions => ['channel_id = ?', channel], :order => 'created_at ASC')
          channel.earliest_video_id = save.video_id
        end

        if save = Save.find(:first, :conditions => ['channel_id = ?', channel], :order => 'created_at DESC')
          channel.latest_video_id = save.video_id
        end
        channel.save
      end
    # end
  end

  def self.down
    
  end
end
