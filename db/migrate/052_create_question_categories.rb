class CreateQuestionCategories < ActiveRecord::Migration
  def self.up
    create_table :question_categories do |t|
      t.column :position, :integer
      t.column :name, :string, :default => '', :null => false
    end
  end

  def self.down
    drop_table :question_categories
  end
end
