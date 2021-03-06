class CreateSubscriptionMessages < ActiveRecord::Migration
  def self.up
    create_table :subscription_messages, :id => false do |t|
      t.column :user_id, :integer
      t.column :saved_video_id, :integer
      t.column :video_id, :integer
      t.timestamps
    end
    
    add_index :subscription_messages, [:user_id, :saved_video_id], :name => 'index_subscriptions_messages_select'
  end

  def self.down
    drop_table :subscription_messages
  end
end
