class CreateUserSubmissions < ActiveRecord::Migration
  def self.up
    create_table :user_submissions do |t|
      t.integer     :user_id, :null => false
      t.string      :title, :null => false
      t.text        :description
      t.string      :url, :null => false
      t.integer     :channel_id, :null => false
      t.integer     :category_id, :null => false

      t.integer     :status, :null => false, :default => 1
      t.integer     :video_id
      t.integer     :processed_by_id, :references => :users
      t.timestamp   :processed_at

      t.timestamps
    end
  end

  def self.down
    drop_table :user_submissions
  end
end
