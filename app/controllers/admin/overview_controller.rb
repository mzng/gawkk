class Admin::OverviewController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def index
    job_queue_status
  end
  
  def update_job_queue_status
    job_queue_status
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
  
  def job_queue_status
    @actual_job_queue_size = Job.count(:all, :conditions => {:state => 'queued'})
    @cached_job_queue_size = Rails.cache.read("job_queue/size")
  end
end
