class CreateDislikes < ActiveRecord::Migration
  def self.up
    create_table :dislikes do |t|
      t.column    :user_id, :integer
      t.column    :video_id, :integer
      t.timestamps
    end

    add_column  :videos, :dislikes_count, :integer, :default => 0

    add_index :dislikes, :video_id
    add_index :dislikes, :created_at
  end

  def self.down
    drop_table :dislikes

    remove_column :videos, :dislikes_count
  end
end
