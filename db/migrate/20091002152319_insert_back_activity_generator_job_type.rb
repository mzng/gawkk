class InsertBackActivityGeneratorJobType < ActiveRecord::Migration
  def self.up
    JobType.create :name => 'back_activity_generator', :description => 'Back generates ActivityMessages for a User who has become active.'
  end

  def self.down
    JobType.find_by_name('back_activity_generator').destroy
  end
end
