class AddSearchStatusToParameters < ActiveRecord::Migration
  def self.up
    Parameter.create :name => 'search_status', :value => 'false'
  end

  def self.down
    Parameter.find_by_name('search_status').destroy
  end
end
