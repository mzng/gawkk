require 'oauth'

class Util::Twitter
  
  # Basic
  def self.client
    Twitter::Client.configure do |config|
      config.user_agent = 'Gawkk'
      config.application_name = 'gawkk'
      config.application_url = 'http://gawkk.com'
      config.source = 'gawkk'
    end
    
    Twitter::Client.new(:login => 'gawkk', :password => 'gcgcgcgc')
  end
  
  # OAuth
  def self.config
    config = Hash.new
    
    if Rails.env.production?
      config[:key]    = 'dVb5CVt70JVa2rzCzuBKOQ'
      config[:secret] = '3V2rYi0gkV3Ls2IfZfS0ivBlb7twMAUpszQZ6tRWNw'
    else
      config[:key]    = 'mO05dsAgQWJzZGwLXG1YA'
      config[:secret] = 'fCzbiKbozLoLwnX22x1KG2GcCzhJo9eLHYtChkLEeMU'
    end
    
    return config
  end
  
  def self.consumer
    OAuth::Consumer.new(Util::Twitter.config[:key], Util::Twitter.config[:secret], {:site => "http://twitter.com"})
  end
  
  def self.request(http_method, path, access_token, access_secret)
    token = OAuth::AccessToken.new(Util::Twitter.consumer, access_token, access_secret)
    response = Util::Twitter.consumer.request(http_method, path, token, {:scheme => :query_string})
    
    case response
    when Net::HTTPOK
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        response.body
      end
    when Net::HTTPUnauthorized
      raise Util::Twitter::Unauthorized, 'The credentials provided did not authorize the user.'
    else
      message = begin
        JSON.parse(response.body)['error']
      rescue JSON::ParserError
        if match = response.body.match(/<error>(.*)<\/error>/)
          match[1]
        else
          'An error occurred processing your Twitter request.'
        end
      end
      
      raise Util::Twitter::HTTPError, message
    end
  end
  
  class HTTPError < StandardError; end
  class Unauthorized < HTTPError; end
end
