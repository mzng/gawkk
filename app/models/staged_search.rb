class StagedSearch < ActiveRecord::Base
  def self.for_front_page
    find(:all, :order => "query asc", :limit => 100)
  end

 end
