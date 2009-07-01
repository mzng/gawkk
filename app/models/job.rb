class Job < ActiveRecord::Base
  acts_as_state_machine :initial => :queued
  
  belongs_to :job_type
  belongs_to :processable, :polymorphic => true
  
  state :queued
  state :processing, :enter => Proc.new {|job| job.update_attribute('dequeued_at', Time.now)}
  state :completed, :enter => Proc.new {|job| job.update_attribute('completed_at', Time.now)}
  state :failed, :enter => Proc.new {|job| job.update_attribute('completed_at', Time.now)}
  
  event :process do
    transitions :to => :processing, :from => :queued
  end
  
  event :complete do
    transitions :to => :completed, :from => :processing
  end
  
  event :fail do
    transitions :to => :failed, :from => :processing
  end
  
  
  def before_create
    self.enqueued_at = Time.now if self.enqueued_at.blank?
    
    return true
  end
  
  
  def self.enqueue(*args)
    options = args.extract_options!

    if options[:type].blank?
      options[:type] = Rails.cache.fetch("job_types/default", :expires_in => 1.week) do
        JobType.find_by_name('activity')
      end
    end

    if Job.create(:job_type_id => options[:type].id, :processable_type => options[:processable].class.name, :processable_id => options[:processable].id)
      if !Rails.cache.exist?("job_queue/size")
        Rails.cache.write("job_queue/size", Job.count(:all, :conditions => {:state => 'queued'}), :expires_in => 1.week)
      else
        Util::Cache.increment("job_queue/size")
      end
    end
  end
  
  def self.dequeue
    queue_size = Rails.cache.fetch("job_queue/size", :expires_in => 1.week) do
      Job.count(:all, :conditions => {:state => 'queued'})
    end
    
    job = ((queue_size > 0 and (j = Job.find(:first, :conditions => {:state => 'queued'}, :order => 'id ASC'))) ? j : nil)
    
    if !job.nil?
      if !Rails.cache.exist?("job_queue/size")
        Rails.cache.write("job_queue/size", queue_size, :expires_in => 1.week)
      end
      
      Util::Cache.decrement("job_queue/size")
    end
    
    return job
  end
end
