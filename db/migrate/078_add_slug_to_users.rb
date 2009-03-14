class AddSlugToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :slug, :string
    User.reset_column_information
    
    User.find(:all).each do |user|
      user.update_attribute('slug', Util::Slug.generate(user.username, false))
    end
  end

  def self.down
    remove_column :users, :slug
  end
end
