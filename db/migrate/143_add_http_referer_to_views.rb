class AddHttpRefererToViews < ActiveRecord::Migration
  def self.up
    add_column :views, :http_referer, :text
  end

  def self.down
    remove_column :views, :http_referer
  end
end
