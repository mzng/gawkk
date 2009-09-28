class Util::Facebook
  def self.config
    config = Hash.new
    
    # if Rails.env.production?
    #   config[:key]    = '3b73b34a3d750d20a4f4e86905459ad1'
    #   config[:secret] = '3d4b4a03e7a18aaf52201885c389535b'
    # else
    #   config[:key]    = '6f43f1ad90bf57624b102ad2e7a59331'
    #   config[:secret] = '49b6081049b801c74fffae0fe4292092'
    # end
    
    config[:key]    = '093158e95304546cd3277069c250b15b'
    config[:secret] = 'b226ec7a3b9dc98743ddf35bcba581e2'
    
    return config
  end
end