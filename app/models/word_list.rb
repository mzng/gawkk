class WordList < ActiveRecord::Base
  has_many :words, :order => 'value', :dependent => :destroy
  
  validates_presence_of :name, :on => :save, :message => "can't be blank"
  
  def self.collect_word_lists
    word_lists = Hash.new
    word_lists['Porn Words'] = Hash.new
    Word.find(:all, :conditions => ['word_list_id = ?', WordList.find_by_name('Porn Words')], :order => 'value').each do |word|
      word_lists['Porn Words'][word.value] = word.value
    end
    
    word_lists['Spanish'] = Hash.new
    Word.find(:all, :conditions => ['word_list_id = ?', WordList.find_by_name('Spanish')], :order => 'value').each do |word|
      word_lists['Spanish'][word.value] = word.value
    end
    
    return word_lists
  end
  
  def self.collect_negative_keywords(query)
    q = query.downcase
    keyword_string = ''
    keywords = Word.find(:all, :conditions => ['word_list_id = ?', WordList.find_by_name('Negative Keywords')], :order => 'value').collect{|word| word.value}
    
    collected = false
    q.split.each do |word|
      if !collected and keywords.include?(word)
        keywords.delete(word)
        keyword_string = ' NOT (' + keywords.join(' OR ') + ')'
        collected = true
      end
    end
    
    return keyword_string
  end
end
