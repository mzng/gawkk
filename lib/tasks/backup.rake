require 'aws/s3'
# require 's3_aws_fix'
require 'ftools'

namespace :backup do
  task :db => :environment do
    # Define list of eligible backup days
    today = Time.now
    todays_date = today.strftime("%Y-%m-%d")
    
    eligible_backup_days = Array.new
    last_weekly_backup_day = (today - today.strftime("%w").to_i.days)
    for i in 0..6
      eligible_backup_days << (today - i.days).strftime("%Y-%m-%d")
      eligible_backup_days << (last_weekly_backup_day - i.weeks).strftime("%Y-%m-%d")
    end
    
    eligible_backup_days.uniq!
    eligible_backup_days.sort!
    
    # Backup database and upload to Amazon S3
    `rake backup RAILS_ENV=production`
    
    # Cleanup raw .sql backup file
    if File.exists?("/tmp/gawkk_#{todays_date}_db.sql")
      File.delete("/tmp/gawkk_#{todays_date}_db.sql")
    end
    
    # Move .tar.gz sql backup file to backups directory
    if File.exists?("/tmp/gawkk_#{todays_date}_db.tar.gz")
      File.move("/tmp/gawkk_#{todays_date}_db.tar.gz", "/var/www/apps/gawkk/shared/backups/gawkk_#{todays_date}_db.tar.gz")
    end
    
    # Remove old .tar.gz sql backup files from the backups directory
    Dir.new('/var/www/apps/gawkk/shared/backups/').each do |file|
      if file.match(/^gawkk_(.)*_db\.tar\.gz$/)
        file_date = file[6, file.length - 16]
        if !eligible_backup_days.include?(file_date)
          File.delete("/var/www/apps/gawkk/shared/backups/#{file}")
        end
      end
    end
    
    # Connect to Amazon S3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => '1SMFTD6EHSSCK56P15R2',
      :secret_access_key => 'HqYDpHjKykFzsUQmcKbZkxQbhO8jzPY9VzPomxJV'
    )
    
    # Remove old .tar.gz sql backup files from the gawkk_backup Amazon S3 bucket
    backup_bucket = AWS::S3::Bucket.find('gawkk_backup')
    backup_bucket.objects.each do |backup|
      if backup.key.match(/^gawkk(.)*_db\.tar\.gz$/)
        file_date = backup.key[6, backup.key.length - 16]
        if !eligible_backup_days.include?(file_date)
          AWS::S3::S3Object.delete(backup.key, 'gawkk_backup')
        end
      end
    end
  end
  
  task :logs => :environment do
    # Connect to Amazon S3
    AWS::S3::Base.establish_connection!(
      :access_key_id     => '1SMFTD6EHSSCK56P15R2',
      :secret_access_key => 'HqYDpHjKykFzsUQmcKbZkxQbhO8jzPY9VzPomxJV'
    )
    
    # Create a hash to store GET/PUT statistics
    stats = Hash.new
    
    # Setup a log file for gawkk_user_thumbnail s3 logs
    s3_user_thumbnails_log = File.new("#{RAILS_ROOT}/log/gawkk_user_thumbnails.s3.log",  "a")
    
    # Collect GET/PUT statistics for gawkk_user_thumbnails
    stats[:gawkk_user_thumbnails] = Hash.new
    stats[:gawkk_user_thumbnails][:get] = 0
    stats[:gawkk_user_thumbnails][:put] = 0
    puts "AWS::S3::Bucket.logs('gawkk_user_thumbnails').size=#{AWS::S3::Bucket.logs('gawkk_user_thumbnails').size}"
    AWS::S3::Bucket.logs('gawkk_user_thumbnails').each do |log|
      begin
        log.lines.each do |line|
          s3_user_thumbnails_log.puts line.time.to_s + ', ' + line.request_uri
          stats[:gawkk_user_thumbnails][:get] = stats[:gawkk_user_thumbnails][:get] + 1 if line.request_uri.match(/^GET /)
          stats[:gawkk_user_thumbnails][:put] = stats[:gawkk_user_thumbnails][:put] + 1 if line.request_uri.match(/^PUT /)
        end
        AWS::S3::S3Object.delete(log.path[23, log.path.length], 'gawkk_user_thumbnails')
      rescue
      end
    end
    s3_user_thumbnails_log.close
    s3_user_thumbnails_log = File.new("#{RAILS_ROOT}/log/gawkk_user_thumbnails.s3.log",  "r")
    stats[:gawkk_user_thumbnails][:log] = s3_user_thumbnails_log
    
    # Setup a log file for gawkk_video_thumbnail s3 logs
    s3_video_thumbnails_log = File.new("#{RAILS_ROOT}/log/gawkk_video_thumbnails.s3.log",  "a")
    
    # Collect GET/PUT statistics for gawkk_video_thumbnails
    stats[:gawkk_video_thumbnails] = Hash.new
    stats[:gawkk_video_thumbnails][:get] = 0
    stats[:gawkk_video_thumbnails][:put] = 0
    puts "AWS::S3::Bucket.logs('gawkk_video_thumbnails').size=#{AWS::S3::Bucket.logs('gawkk_video_thumbnails').size}"
    AWS::S3::Bucket.logs('gawkk_video_thumbnails').each do |log|
      begin
        log.lines.each do |line|
          s3_video_thumbnails_log.puts line.time.to_s + ', ' + line.request_uri
          stats[:gawkk_video_thumbnails][:get] = stats[:gawkk_video_thumbnails][:get] + 1 if line.request_uri.match(/^GET /)
          stats[:gawkk_video_thumbnails][:put] = stats[:gawkk_video_thumbnails][:put] + 1 if line.request_uri.match(/^PUT /)
        end
        AWS::S3::S3Object.delete(log.path[24, log.path.length], 'gawkk_video_thumbnails')
      rescue
      end
    end
    s3_video_thumbnails_log.close
    s3_video_thumbnails_log = File.new("#{RAILS_ROOT}/log/gawkk_video_thumbnails.s3.log",  "r")
    stats[:gawkk_video_thumbnails][:log] = s3_video_thumbnails_log
    
    # Collect backups currently at S3
    stats[:backups] = Array.new
    backup_bucket = AWS::S3::Bucket.find('gawkk_backup')
    backup_bucket.objects.each do |backup|
      if backup.key.match(/^gawkk(.)*_db\.tar\.gz$/)
        begin
          backup_size = " (#{(((backup.size / 1048576.0) * 100).round / 100.0)} MB)"
        rescue
          backup_size = ""
        end
        stats[:backups] << "#{backup.key}#{backup_size}"
      end
    end
    stats[:backups].sort!
    
    # Remove logs from gawkk_backup bucket
    puts "AWS::S3::Bucket.logs('gawkk_backup').size=#{AWS::S3::Bucket.logs('gawkk_backup').size}"
    AWS::S3::Bucket.logs('gawkk_backup').each do |log|
      AWS::S3::S3Object.delete(log.path[14, log.path.length], 'gawkk_backup')
    end
    
    BackupMailer.deliver_logs(stats)
    
    s3_user_thumbnails_log.close
    s3_video_thumbnails_log.close
    
    File.delete("#{RAILS_ROOT}/log/gawkk_user_thumbnails.s3.log")
    File.delete("#{RAILS_ROOT}/log/gawkk_video_thumbnails.s3.log")
  end
end