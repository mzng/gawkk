class Util::Sort
  def self.sort_contacts(contacts, low_index, high_index)
    low_to_high_index = low_index
    high_to_low_index = high_index
    
    pivot_index = (low_to_high_index + high_to_low_index) / 2
    pivot_value = contacts[pivot_index]
    
    new_low_index = high_index + 1
    new_high_index = low_index - 1
    
    while (new_high_index + 1) < new_low_index
      low_to_high_value = contacts[low_to_high_index]
      while low_to_high_index < new_low_index and (low_to_high_value.name.downcase <=> pivot_value.name.downcase) < 0
        new_high_index = low_to_high_index
        low_to_high_index += 1
        low_to_high_value = contacts[low_to_high_index]
      end
      
      high_to_low_value = contacts[high_to_low_index]
      while new_high_index <= high_to_low_index and (high_to_low_value.name.downcase <=> pivot_value.name.downcase) > 0
        new_low_index = high_to_low_index
        high_to_low_index -= 1
        high_to_low_value = contacts[high_to_low_index]
      end
      
      if low_to_high_index == high_to_low_index
        new_high_index = low_to_high_index
      elsif low_to_high_index < high_to_low_index
        if (low_to_high_value.name.downcase <=> high_to_low_value.name.downcase) >= 0
          parking = low_to_high_value
          contacts[low_to_high_index] = high_to_low_value
          contacts[high_to_low_index] = parking
          
          new_low_index = high_to_low_index
          new_high_index = low_to_high_index
          
          low_to_high_index += 1
          high_to_low_index -= 1
        end
      end
    end
    
    if low_index < new_high_index
      Util::Sort.sort_contacts(contacts, low_index, new_high_index)
    end
    
    if new_low_index < high_index
      Util::Sort.sort_contacts(contacts, new_low_index, high_index)
    end
  end
end