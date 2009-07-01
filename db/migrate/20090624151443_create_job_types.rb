class CreateJobTypes < ActiveRecord::Migration
  def self.up
    create_table :job_types do |t|
      t.column :name, :string
      t.column :description, :text
    end
    
    JobType.reset_column_information
    JobType.create :name => 'activity', :description => 'Generates ActivityMessages for Users by processing NewsItems.'
  end

  def self.down
    drop_table :job_types
  end
end
