class Tweet < ActiveRecord::Base
  belongs_to :twitter_account
  belongs_to :tweet_type
  belongs_to :reportable, :polymorphic => true
  
  def after_create
    attempt = 0
    auth_code = ''
    
    if self.reportable_type == 'Video' and !self.reportable.short_code.blank?
      auth_code = self.reportable.short_code
    elsif self.reportable_type == 'Comment' and !self.reportable.commentable.short_code.blank?
      auth_code = self.reportable.commentable.short_code
    else
      while attempt < 10 and (auth_code = Util::AuthCode.generate(6)) and Tweet.find_by_auth_code(auth_code)
        attempt = attempt + 1
        auth_code = ''
      end

      auth_code = self.id.to_s if attempt == 10 or auth_code.blank?
    end
    
    update_attribute('auth_code', auth_code)
  end
  
  def self.report(type, user, reportable)
    if twitter_account = user.twitter_account and twitter_account.authenticated?
      if tweet_type = TweetType.find_by_name(type)
        tweet = Tweet.create :tweet_type_id => tweet_type.id, :twitter_account_id => twitter_account.id, :reportable_type => reportable.class.name, :reportable_id => reportable.id
      end
      tweet.publish if Rails.env.production?
    end
  end
  
  def publish
    twitter_account = self.twitter_account
    status = self.render
    
    # Configure twitter for gawkk
    Twitter::Client.configure do |config|
      config.user_agent = 'Gawkk'
      config.application_name = 'gawkk'
      config.application_url = 'http://gawkk.com'
      config.source = 'gawkk'
    end
    
    twitter = Twitter::Client.new(:login => twitter_account.username, :password => twitter_account.password)
    twitter.status(:post, status)
  end
  
  def render
    status = self.tweet_type.template
    
    if status.match(/\{(.*)?\|/)
      opening = status.match(/\{(.*)?\|/).begin(0)
      closing = status.index('}', status.match(/\{(.*)?\|/).begin(0))
      choices = status[status.match(/\{(.*)?\|/).begin(0) + 1, status.match(/\{(.*)?\|/).begin(0) + closing - 1]
      
      choice  = choices.split('|').rand
      
      to_replace = status[status.match(/\{(.*)?\|/).begin(0), status.match(/\{(.*)?\|/).begin(0) + closing + 1]
      to_replace = to_replace.gsub(/\{/, '\\{')
      to_replace = to_replace.gsub(/\}/, '\\}')
      to_replace = to_replace.gsub(/\|/, '\\|')
      
      status = status.gsub(/#{to_replace}/, choice)
    end
    
    status = status.gsub(/\{channel\}/, trim(plain_text(channel_name(self.reportable.name)))) if self.reportable and self.reportable.class == Channel
    status = status.gsub(/\{video\}/, trim(plain_text(self.reportable.name))) if self.reportable and self.reportable.class == Video
    status = status.gsub(/\{comment\}/, trim(plain_text(self.reportable.body))) if self.reportable and self.reportable.class == Comment
    
    if self.reportable_type == 'Video' and !self.reportable.short_code.blank?
      status = status.concat(" http://gawkk.com/v/#{self.auth_code}")
    elsif self.reportable_type == 'Comment' and !self.reportable.commentable.short_code.blank?
      status = status.concat(" http://gawkk.com/v/#{self.auth_code}")
    else
      status = status.concat(" http://gawkk.com/t/#{self.auth_code}")
    end
    
    return status
  end
  
  private
  def channel_name(name)
    if name.downcase[/^the /]
      return name
    else
      return 'The ' + name
    end
  end
  
  def trim(text)
    available_characters = self.tweet_type.available_characters
    if text.length > available_characters
      text = text[0, available_characters - 3] + '...'
    end
    return text
  end
  
  def plain_text(text)
    text = text.gsub(/&amp;/, '&')
    text = text.gsub(/&apos;/, '\'')
    text = Hpricot(text).to_plain_text
  end
end