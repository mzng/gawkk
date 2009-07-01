class InsertJobQueueParameter < ActiveRecord::Migration
  def self.up
    Parameter.create :name => 'job_queue_enabled', :value => 'false'
  end

  def self.down
    Parameter.find_by_name('job_queue_enabled').destroy
  end
end
