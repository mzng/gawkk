class CreateMessages < ActiveRecord::Migration
  def self.up
    create_table :messages do |t|
      t.column :thread_id, :string, :references => nil
      t.column :reply, :boolean, :default => false, :null => false
      t.column :sender_id, :integer, :references => :users
      t.column :sender_email, :string
      t.column :receiver_id, :integer, :references => :users
      t.column :receiver_email, :string
      t.column :shareable_type, :string
      t.column :shareable_id, :integer, :references => nil
      t.column :body, :text
      t.column :read, :boolean, :default => false, :null => false
      t.column :archived_by_sender, :boolean, :default => false, :null => false
      t.column :archived_by_receiver, :boolean, :default => false, :null => false
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :messages
  end
end
