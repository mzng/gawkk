class AddThumbnailToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :thumbnail, :string
    User.reset_column_information
    
    User.find(:all).each do |user|
      # These absolute paths are only for use on the serverss
      if File.exists?("/images/users/#{user.username}.jpg")
        File.rename("/images/users/#{user.username}.jpg", "/images/users/#{user.slug}.jpg")
        user.update_attribute('thumbnail', "users/#{user.slug}.jpg")
      end
    end
  end

  def self.down
    remove_column :users, :thumbnail
  end
end
