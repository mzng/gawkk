class Util::Email
  def self.valid?(email)
    if email =~ /^([+=&'\/\?\^\~a-zA-Z0-9\._-])+@([a-zA-Z0-9_-])+(\.[a-zA-Z0-9_-]+)+/
      true
    else
      false
    end
  end
end