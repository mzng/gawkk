class CreateRatings < ActiveRecord::Migration
  def self.up
    create_table :ratings do |t|
      t.column :user_id, :integer
      t.column :channel_id, :integer
      t.column :value, :decimal
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :ratings
  end
end
