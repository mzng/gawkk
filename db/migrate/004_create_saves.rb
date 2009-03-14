class CreateSaves < ActiveRecord::Migration
  def self.up
    create_table :saves, :id => false do |t|
      t.column :user_id, :integer
      t.column :video_id, :integer
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :saves
  end
end
