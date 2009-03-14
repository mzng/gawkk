class AddIneligibleForPromotionToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :ineligible_for_promotion, :boolean, :default => false
  end

  def self.down
    remove_column :videos, :ineligible_for_promotion
  end
end
