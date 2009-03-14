class BlankSlateSetup < ActiveRecord::Migration
  def self.up
    User.create(:administrator => true,
               :username => 'administrator',
               :password => 'password',
               :email => 'administrator@gawkk.com')
  end

  def self.down
    User.find_by_username('administrator').destroy
  end
end
