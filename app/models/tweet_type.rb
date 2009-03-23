class TweetType < ActiveRecord::Base
  has_many :tweets
  
  def available_characters
    message = self.template.nil? ? '' : self.template
    
    # Remove {variables} for proper computation
    message = message.gsub(/\{channel\}/, '')
    message = message.gsub(/\{video\}/, '')
    message = message.gsub(/\{comment\}/, '')
    
    # Random message? Choose the longest one to use for this computation
    if message.match(/\{(.*)?\|/)
      opening = message.match(/\{(.*)?\|/).begin(0)
      closing = message.index('}', message.match(/\{(.*)?\|/).begin(0))
      choices = message[message.match(/\{(.*)?\|/).begin(0) + 1, message.match(/\{(.*)?\|/).begin(0) + closing - 1]
      
      choices = choices.split('|')
      max_length_choice = choices[0]
      for i in (1..choices.length - 2)
        if choices[i].length > max_length_choice.length
          max_length_choice = choices[i]
        end
      end
      
      to_replace = message[message.match(/\{(.*)?\|/).begin(0), message.match(/\{(.*)?\|/).begin(0) + closing + 1]
      to_replace = to_replace.gsub(/\{/, '\\{')
      to_replace = to_replace.gsub(/\}/, '\\}')
      to_replace = to_replace.gsub(/\|/, '\\|')
      
      message = message.gsub(/#{to_replace}/, max_length_choice)
      
      puts max_length_choice
      puts message
    end
    
    remaining = 140
    remaining = remaining - message.length
    remaining = remaining - " http://gawkk.com/t/123456".length
    return remaining
  end
end
