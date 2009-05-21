class Util::Facebook
  def self.config
    config = Hash.new
    
    if Rails.env.production?
      config[:key]    = ''
      config[:secret] = ''
    else
      config[:key]    = '6f43f1ad90bf57624b102ad2e7a59331'
      config[:secret] = '49b6081049b801c74fffae0fe4292092'
    end
    
    return config
  end
end