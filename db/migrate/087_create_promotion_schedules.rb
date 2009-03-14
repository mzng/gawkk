class CreatePromotionSchedules < ActiveRecord::Migration
  def self.up
    create_table :promotion_schedules do |t|
      t.column :category_id, :integer
      t.column :hour, :integer, :null => false
      t.column :number_of_promotions, :integer, :null => false
    end
    PromotionSchedule.reset_column_information
    
    Category.find(:all, :order => 'position').each do |category|
      [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23].each do |hour|
        PromotionSchedule.create :category_id => category.id, :hour => hour, :number_of_promotions => 0
      end
    end
  end

  def self.down
    drop_table :promotion_schedules
  end
end
