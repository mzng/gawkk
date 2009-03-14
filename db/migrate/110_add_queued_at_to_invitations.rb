class AddQueuedAtToInvitations < ActiveRecord::Migration
  def self.up
    add_column :invitations, :queued_at, :timestamp
  end

  def self.down
    remove_column :invitations, :queued_at
  end
end
