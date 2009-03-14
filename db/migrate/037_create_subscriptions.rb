class CreateSubscriptions < ActiveRecord::Migration
  def self.up
    create_table :subscriptions do |t|
      t.column :channel_id, :integer
      t.column :user_id, :integer
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :subscriptions
  end
end
