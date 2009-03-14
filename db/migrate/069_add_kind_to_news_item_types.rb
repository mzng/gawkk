class AddKindToNewsItemTypes < ActiveRecord::Migration
  def self.up
    remove_column :news_item_types, :about_user
    add_column :news_item_types, :kind, :string, :default => '', :null => false
  end

  def self.down
    remove_column :news_item_types, :kind
    add_column :news_item_types, :about_user, :boolean
  end
end
