class FetchIdsForTwitterAccounts < ActiveRecord::Migration
  def self.up
    TwitterAccount.find(:all, :conditions => {:authenticated => true}).each do |account|
      begin
        response = account.dispatcher.get('/account/verify_credentials')
        account.update_attribute('twitter_user_id', response['id'])
      rescue TwitterDispatch::Unauthorized
        account.update_attribute('authenticated', false)
      end
    end
  end

  def self.down
    TwitterAccount.find(:all, :conditions => {:authenticated => true}).each do |account|
      account.update_attribute('twitter_user_id', '')
    end
  end
end
