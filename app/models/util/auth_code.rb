class Util::AuthCode
  def self.generate(length = 8)
    possible_characters = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    return Array.new(length, '').collect{possible_characters[rand(possible_characters.size - 1)]}.join
  end
end