class CreateThresholdTypes < ActiveRecord::Migration
  def self.up
    create_table :threshold_types do |t|
      t.column :name,         :string
      t.column :description,  :string
    end
    
    ThresholdType.reset_column_information
    ThresholdType.create :name => 'number_of_saves', :description => 'Saves'
    ThresholdType.create :name => 'number_of_videos', :description => 'Top ranked in past 24 hours'
    ThresholdType.create :name => 'percentage_of_videos', :description => 'Top percent in past 24 hours'
    
    add_column :categories, :threshold_type_id, :integer
    add_column :categories, :threshold,         :integer
    execute "UPDATE categories SET threshold_type_id = 1, threshold = 3"
  end

  def self.down
    remove_column :categories, :threshold
    remove_column :categories, :threshold_type_id
    drop_table :threshold_types
  end
end
