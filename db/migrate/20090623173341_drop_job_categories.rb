class DropJobCategories < ActiveRecord::Migration
  def self.up
    drop_table :job_categories
  end

  def self.down
  end
end
