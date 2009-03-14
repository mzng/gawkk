class AddSaltToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :salt, :string
    User.reset_column_information
    
    User.find(:all, :conditions => 'users.feed_owner = false').each do |user|
      user.update_attribute('salt', [Array.new(6){rand(256).chr}.join].pack("m").chomp)
    end
  end

  def self.down
    remove_column :users, :salt
  end
end
