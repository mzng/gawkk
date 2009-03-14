class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.column :category_id, :integer
      t.column :name, :string
      t.column :slug, :string
      t.column :description, :text
      t.column :url, :string
      t.column :posted_by_id, :integer, :references => :users
    end
  end

  def self.down
    drop_table :videos
  end
end
