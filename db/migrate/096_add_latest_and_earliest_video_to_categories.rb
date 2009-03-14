class AddLatestAndEarliestVideoToCategories < ActiveRecord::Migration
  def self.up
    add_column :categories, :earliest_popular_video_id, :integer, :references => :videos
    add_column :categories, :earliest_video_id, :integer, :references => :videos
    
    add_column :categories, :latest_popular_video_id, :integer, :references => :videos
    add_column :categories, :latest_video_id, :integer, :references => :videos
    
    Category.reset_column_information
    Category.find(:all, :order => 'position').each do |category|
      category.earliest_popular_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NOT NULL', category.id], :order => 'promoted_at ASC')
      category.earliest_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NULL', category.id], :order => 'posted_at ASC')
      category.latest_popular_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NOT NULL', category.id], :order => 'promoted_at DESC')
      category.latest_video = Video.find(:first, :conditions => ['category_id = ? AND promoted_at IS NULL', category.id], :order => 'posted_at DESC')
      category.save
    end
  end

  def self.down
    remove_column :categories, :latest_video_id
    remove_column :categories, :latest_popular_video_id
    remove_column :categories, :earliest_video_id
    remove_column :categories, :earliest_popular_video_id
  end
end
