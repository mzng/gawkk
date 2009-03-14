class CreateQuestions < ActiveRecord::Migration
  def self.up
    create_table :questions do |t|
      t.column :question_category_id, :integer
      t.column :position, :integer
      t.column :title, :string, :default => '', :null => false
      t.column :answer, :text, :default => '', :null => false
    end
  end

  def self.down
    drop_table :questions
  end
end
