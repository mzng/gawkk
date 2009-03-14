class AddOptimiztionIndexes < ActiveRecord::Migration
  def self.up
    add_index :videos, [:url, :truveo_url], :name => "urls"
    # execute "ALTER TABLE `gawkk_production`.`videos` DROP INDEX `category_id`, ADD INDEX category_id USING BTREE(`category_id`, `promoted_at`);"
  end

  def self.down
    remove_index :videos, :name => :urls
    execute "ALTER TABLE `gawkk_production`.`videos` DROP INDEX `category_id`, ADD INDEX category_id USING BTREE(`category_id`);"
  end
end
