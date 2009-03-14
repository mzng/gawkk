class AddSourceDomainToVideos < ActiveRecord::Migration
  def self.up
    add_column :videos, :source_domain, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :videos, :source_domain
  end
end
