class CreateJobsForJobQueue < ActiveRecord::Migration
  def self.up
    create_table :jobs do |t|
      t.column :state, :string
      t.column :job_type_id, :integer
      t.column :processable_type, :string
      t.column :processable_id, :integer, :references => nil
      t.column :enqueued_at, :timestamp
      t.column :dequeued_at, :timestamp
      t.column :completed_at, :timestamp
    end
  end

  def self.down
    drop_table :jobs
  end
end
