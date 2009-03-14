class Util::Twitter
  def self.client
    Twitter::Client.configure do |config|
      config.user_agent = 'Gawkk'
      config.application_name = 'gawkk'
      config.application_url = 'http://gawkk.com'
      config.source = 'gawkk'
    end
    
    Twitter::Client.new(:login => 'gawkk', :password => 'gcgcgcgc')
  end
end