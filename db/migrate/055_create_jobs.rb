class CreateJobs < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.column :job_category_id, :integer
      t.column :position, :integer
      t.column :title, :string, :default => '', :null => false
      t.column :description, :text, :default => '', :null => false
    end
  end

  def self.down
    drop_table :jobs
  end
end
