class InsertFrontPageSubscriptionPreviewParameter < ActiveRecord::Migration
  def self.up
    Parameter.create :name => 'front_page_subscription_preview_enabled', :value => 'true'
  end

  def self.down
    Parameter.find_by_name('front_page_subscription_preview_enabled').destroy
  end
end
