class AddSimpleTemplateToNewsItemTypes < ActiveRecord::Migration
  def self.up
    add_column :news_item_types, :simple_template, :string, :default => ''
    
    NewsItemType.reset_column_information
    NewsItemType.find_by_name('submit_a_video').update_attribute('simple_template', '{user} posted this video')
    NewsItemType.find_by_name('like_a_video').update_attribute('simple_template', '{user} liked this video')
    NewsItemType.find_by_name('make_a_comment').update_attribute('simple_template', '{user}{comment}')
  end

  def self.down
    remove_column :news_item_types, :simple_template
  end
end
