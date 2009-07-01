class DropQuestionCategories < ActiveRecord::Migration
  def self.up
    drop_table :question_categories
  end

  def self.down
  end
end
