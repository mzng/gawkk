class AddAdCampaignToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :ad_campaign, :string
  end

  def self.down
    remove_column :users, :ad_campaign
  end
end
