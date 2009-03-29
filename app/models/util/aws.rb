class Util::AWS
  def self.connect
    RightAws::S3.new('1SMFTD6EHSSCK56P15R2', 'HqYDpHjKykFzsUQmcKbZkxQbhO8jzPY9VzPomxJV')
  end
  
  def self.clean(bucket)
    bucket.keys('prefix' => 'log-').each do |key|
      if key.owner.name == 's3-log-service'
        key.delete
      end
    end
  end
end