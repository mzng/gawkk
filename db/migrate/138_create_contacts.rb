class CreateContacts < ActiveRecord::Migration
  def self.up
    create_table :contacts do |t|
      t.column :user_id, :integer
      t.column :name, :string
      t.column :email, :string
      t.column :created_at, :timestamp
    end
    
    Contact.reset_column_information
    Invitation.find(:all, :conditions => ['accepted_at IS NULL']).each do |invitation|
      Contact.create :user_id => invitation.host_id, :name => '', :email => invitation.invitee_email
    end
  end
  
  def self.down
    drop_table :contacts
  end
end
