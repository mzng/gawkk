class AddDigestEmailFrequencyToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :digest_email_frequency, :integer, :default => 0, :null => false
    
    User.reset_column_information
    User.update_all('digest_email_frequency = 3', 'feed_owner = false AND send_digest_emails = true')
  end

  def self.down
    remove_column :users, :digest_email_frequency
  end
end
