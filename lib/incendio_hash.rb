# Rails.cache freezes values in a Hash cached directly.
# Use this Hash wrapper to prevent that from happening.

class IncendioHash
  attr_accessor :cache_key, :hash
  
  def initialize(cache_key)
    self.cache_key = cache_key
    self.hash = Hash.new
  end
  
  def method_missing(sym, *args, &block)
    return_value = hash.send(sym, *args, &block)
    Rails.cache.write(cache_key, self)
    
    return return_value
  end
end