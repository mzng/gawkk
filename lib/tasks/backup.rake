namespace :backup do
  task :status => :environment do
    # Connect to Amazon S3
    s3 = Util::AWS.connect
    files = Hash.new
    
    
    # Process Backup Files
    files[:database] = Array.new
    
    # Collect Backup Files
    bucket = s3.bucket('gawkk_backup')
    bucket.keys('prefix' => 'gawkk_').each do |key|
      files[:database] << key.name + " (#{(((key.size / 1048576.0) * 100).round / 100.0)} MB)"
    end
    Util::AWS.clean(bucket)
    
    # Remove Old Backup Files in /tmp
    Rake::Task['backup:clean_up_that_damn_tmp_dir'].invoke
    
    
    # Process Images
    files[:images] = Array.new
    yesterday = Time.now - 1.day
    
    # Collect User Avatars
    bucket = s3.bucket('gawkk_user_thumbnails')
    bucket.keys('prefix' => "user/").each do |key|
      if key.last_modified.strftime("%Y/%m/%d") == yesterday.strftime("%Y/%m/%d")
        files[:images] << key.name
      end
    end
    Util::AWS.clean(bucket)
    
    # Collect Video Thumbnails
    bucket = s3.bucket('gawkk_video_thumbnails')
    bucket.keys('prefix' => "video/#{yesterday.strftime("%Y/%m/%d")}/").each do |key|
      files[:images] << key.name
    end
    Util::AWS.clean(bucket)
    
    
    # Deliver Status Update
    BackupMailer.deliver_status_update(files)
  end
  
  task :clean_up_that_damn_tmp_dir => :environment do
    puts 'Before'
    files = `ls /tmp/gawkk_*_db.tar*`.split
    files.each do |filename|
      puts ' - ' + filename
    end
    puts ''
    
    if files.size > 10
      files.first(files.size - 10).each do |filename|
        `rm -f /tmp/#{filename}`
      end
    end
    
    puts 'After'
    files = `ls /tmp/gawkk_*_db.tar*`.split
    files.each do |filename|
      puts ' - ' + filename
    end
  end
end