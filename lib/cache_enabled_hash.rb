# Rails.cache freezes values in a Hash cached directly.
# Use this Hash wrapper to prevent that from happening.

class CacheEnabledHash
  attr_accessor :cache_key, :expires_in, :hash
  
  def initialize(cache_key, expires_in = 1.week)
    self.cache_key = cache_key
    self.expires_in = expires_in
    self.hash = Hash.new
  end
  
  def method_missing(sym, *args, &block)
    return_value = hash.send(sym, *args, &block)
    
    # Unless a values is being read from the hash, update the copy in memcached
    Rails.cache.write(self.cache_key, self, :expires_in => self.expires_in) unless sym.to_s == '[]'
    
    return return_value
  end
end