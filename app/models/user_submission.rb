class UserSubmission < ActiveRecord::Base
  belongs_to :processed_by, :class_name => "User", :foreign_key => "processed_by_id"
  belongs_to :video

  def self.all_open
    find(:all, :conditions => { :status => 1 }, :order => "created_at asc")
  end

  def self.all_approved
    find(:all, :conditions => { :status => 2 }, :order => "processed_at desc")
  end

  def self.all_declined
    find(:all, :conditions => { :status => 3 }, :order => "processed_at desc")
  end

  def load_title
    #begin
     self.url = Util::Scrub.url(self.url)
     self.title = Util::Title.from_url(self.url) 
     !title.blank?
    #rescue
    #  return false
    #end
  end

  def approve!(user)
    self.status = 2
    self.processed_at = Time.now
    self.processed_by_id = user.id

    video = Video.new
    video.url = self.url
    video.url = Util::Scrub.url(video.url) if !video.url.blank?
    if (existing_video = Video.find_by_hashed_url(Digest::SHA2.hexdigest(video.url.nil? ? '' : video.url))).nil?
      video.name = self.title.blank? ? Util::Title.from_url(video.url) : self.title
      video.description = self.description.blank? ? video.name : self.description
      video.slug = Util::Slug.generate(video.title) ### ? title != name ?
      video.embed_code = Util::EmbedCode.generate(video, video.url)
      video.category_id = self.category_id
      video = Util::Thumbnail.suggest(video)
      video.posted_by_id = Channel.find(self.channel_id).user_id
      video.save
    else
      video = existing_video
    end

    self.video_id = video.id
    self.save
  end

  def decline!(user)
    self.status = 3
    self.processed_at = Time.now
    self.processed_by_id = user.id
    self.save
  end
end
