class DropQuestions < ActiveRecord::Migration
  def self.up
    drop_table :questions
  end

  def self.down
  end
end
