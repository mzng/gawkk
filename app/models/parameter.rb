class Parameter < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name
  
  def status?
    return (self.value == 'true') ? true : false
  end
  
  def self.status?(parameter)
    return Parameter.find_by_name(parameter).status?
  end
  
  
  def toggle!
    update_attribute('value', (status? ? 'false' : 'true'))
  end
  
  def self.toggle!(parameter)
    Parameter.find_by_name(parameter).toggle!
  end
  
  
  def self.set(parameter, value)
    Parameter.find_by_name(parameter).update_attribute('value', value)
  end
end
