class CreateJobCategories < ActiveRecord::Migration
  def self.up
    create_table :job_categories do |t|
      t.column :position, :integer
      t.column :name, :string, :default => '', :null => false
    end
  end

  def self.down
    drop_table :job_categories
  end
end
