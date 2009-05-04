require 'digest/sha2'

class UpdateHashedUrlsAndIndex < ActiveRecord::Migration
  def self.up
    count = -1
    Video.reset_column_information
    Video.find_in_batches(:batch_size => 1000) { |videos|
      count = count + 1
      puts "count: " + count.to_s
      
      videos.each { |video|
        video.update_attribute('hashed_url', Digest::SHA2.hexdigest(video.url.nil? ? '' : video.url))
      }
    }
    
    add_index :videos, :hashed_url
  end

  def self.down
    remove_index :videos, :hashed_url
  end
end
