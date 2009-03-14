class CreateInvitations < ActiveRecord::Migration
  def self.up
    create_table :invitations do |t|
      t.column :host_id, :integer, :references => :users
      t.column :invitee_email, :string
      t.column :message, :text
      t.column :invited_at, :timestamp
      t.column :accepted, :boolean, :default => false, :null => false
      t.column :invitee_id, :integer, :references => :users
      t.column :accepted_at, :timestamp
    end
  end

  def self.down
    drop_table :invitations
  end
end
