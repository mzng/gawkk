# Rails.cache freezes values in a Hash cached directly.
# Use this Hash wrapper to prevent that from happening.
# The copy in the cache store is automatically kept in sync.

class CacheEnabledHash
  attr_accessor :hash, :cache_key, :expires_in
  
  def initialize(hash, cache_key, expires_in = 1.week)
    self.cache_key = cache_key
    self.expires_in = expires_in
    
    self.hash = Hash.new
    hash.each_pair do |key, value|
      self.hash[key.to_sym] = value
    end
  end
  
  def method_missing(sym, *args, &block)
    return_value = hash.send(sym, *args, &block)
    
    # Unless a value is being read from the hash, update the copy in memcached to reflect any changes
    Rails.cache.write(self.cache_key, self, :expires_in => self.expires_in) unless sym.to_s == '[]'
    
    return return_value
  end
end