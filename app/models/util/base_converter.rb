class Util::BaseConverter
  @@chars = '23456789abcdefghjkmnpqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ'
  
  def self.to_base54(base10)
    num = base10
    base54 = ''

    while num >= @@chars.length
      remainder = num % @@chars.length
      num = num / @@chars.length
      base54 = @@chars[remainder, 1].to_s + base54
    end

    base54 = @@chars[num, 1].to_s + base54
    
    return base54
  end
  
  def self.to_base10(base54)
    base54 = base54.to_s
    
    if base54[/\)$/]
      base54 = base54[0, base54.length - 1]
    end
    
    base10 = 0
    count = 0

    while !base54.blank?
      char = base54[base54.length - 1, 1]
      base10 = base10 + @@chars.index(char) * @@chars.length**count
      base54 = base54[0, base54.length - 1]
      count = count + 1
    end
    
    return base10.to_i
  end
end