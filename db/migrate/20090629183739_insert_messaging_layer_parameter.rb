class InsertMessagingLayerParameter < ActiveRecord::Migration
  def self.up
    Parameter.create :name => 'messaging_layer_enabled', :value => 'false'
  end

  def self.down
    Parameter.find_by_name('messaging_layer_enabled').destroy
  end
end
