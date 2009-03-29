namespace :backup do
  task :status => :environment do
    # Connect to Amazon S3
    s3 = Util::AWS.connect
    
    # Process Backup Files
    files = Array.new
    
    # Collect Backup Files
    bucket = s3.bucket('gawkk_backup')
    bucket.keys('prefix' => 'gawkk_').each do |key|
      files << key.name + " (#{(((key.size / 1048576.0) * 100).round / 100.0)} MB)"
    end
    Util::AWS.clean(bucket)
    
    BackupMailer.deliver_database_status_update(files)
    
    
    # Process Images
    files = Array.new
    yesterday = Time.now - 1.day
    
    # Collect User Avatars
    bucket = s3.bucket('gawkk_user_thumbnails')
    bucket.keys('prefix' => "user/").each do |key|
      if key.last_modified.strftime("%Y/%m/%d") == yesterday.strftime("%Y/%m/%d")
        files << key.name
      end
    end
    Util::AWS.clean(bucket)
    
    # Collect Video Thumbnails
    bucket = s3.bucket('gawkk_video_thumbnails')
    bucket.keys('prefix' => "video/#{yesterday.strftime("%Y/%m/%d")}/").each do |key|
      files << key.name
    end
    Util::AWS.clean(bucket)
    
    BackupMailer.deliver_image_status_update(files)
  end
end