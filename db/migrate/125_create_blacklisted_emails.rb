class CreateBlacklistedEmails < ActiveRecord::Migration
  def self.up
    create_table :blacklisted_emails do |t|
      t.column :auth_code, :string
      t.column :email, :string
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :blacklisted_emails
  end
end
