class InsertFrontPageSidebarParameter < ActiveRecord::Migration
  def self.up
    Parameter.create :name => 'front_page_sidebar_enabled', :value => 'true'
  end

  def self.down
    Parameter.find_by_name('front_page_sidebar_enabled').destroy
  end
end
