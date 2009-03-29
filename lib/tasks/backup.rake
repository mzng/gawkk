namespace :backup do
  namespace :status do
    task :database do
      s3 = RightAws::S3.new('1SMFTD6EHSSCK56P15R2', 'HqYDpHjKykFzsUQmcKbZkxQbhO8jzPY9VzPomxJV')
      
      backup_files = Array.new
      backup_bucket = s3.bucket('gawkk_backup')
      backup_bucket.keys('prefix' => 'gawkk_').each do |key|
        backup_files << key.name + " (#{(((key.size / 1048576.0) * 100).round / 100.0)} MB)"
      end
      
      BackupMailer.deliver_database_status_update(backup_files)
    end
  end
end