class CreateThresholdAdjustments < ActiveRecord::Migration
  def self.up
    create_table :threshold_adjustments do |t|
      t.column :category_id, :integer
      t.column :hour, :integer
      t.column :position, :integer
      t.column :saves_in_previous_hour, :integer
      t.column :saves_in_previous_24_hours, :integer
      t.column :promotions_in_previous_hour, :integer
      t.column :promotions_in_previous_24_hours, :integer
      t.column :previous_threshold, :integer
      t.column :calculated_threshold, :integer
      t.column :used_previous_adjustment, :boolean, :default => false
      t.column :created_at, :timestamp
    end
  end

  def self.down
    drop_table :threshold_adjustments
  end
end
