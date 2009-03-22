class Word < ActiveRecord::Base
  belongs_to :word_list
  
  validates_presence_of :word_list_id, :on => :save, :message => "can't be blank"
  validates_presence_of :value, :on => :save, :message => "can't be blank"
  
  validates_uniqueness_of :value, :scope => :word_list_id, :on => :create, :message => "must be unique"
  
  def after_save
    Rails.cache.delete("words/all")
  end
  
  def self.collect_all
    Rails.cache.fetch("words/all", :expires_in => 14.days) {
      Word.find(:all).collect{|word| word.value}
    }
  end
end
