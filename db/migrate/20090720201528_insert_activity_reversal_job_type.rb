class InsertActivityReversalJobType < ActiveRecord::Migration
  def self.up
    JobType.create :name => 'activity_reversal', :description => 'Destroys ActivityMessages for a NewsItem and properly unhides the previous ActivityMessage to take its place.'
  end

  def self.down
    JobType.find_by_name('activity_reversal').destroy
  end
end
