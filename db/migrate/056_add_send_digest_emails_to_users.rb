class AddSendDigestEmailsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :send_digest_emails, :boolean, :default => false, :null => false
  end

  def self.down
    remove_column :users, :send_digest_emails
  end
end
