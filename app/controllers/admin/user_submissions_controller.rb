class Admin::UserSubmissionsController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'

  def index
    @submissions = UserSubmission.all_open
  end
  
  def approved
    @submissions = UserSubmission.all_approved
  end

  def declined
    @submissions = UserSubmission.all_declined
  end

  def approve
    @submission = UserSubmission.find(params[:id])
    @submission.approve!(logged_in_user)

    Rails.cache.expire("c_s_#{@submission.video.posted_by}_n_0")

    redirect_to :action => :index
  end

  def decline
    @submission = UserSubmission.find(params[:id])
    @submission.decline!(logged_in_user)
    


    redirect_to :action => :index
  end

  def edit
    @categories = Category.all(:order => "name asc")
    @submission = UserSubmission.find(params[:id])
    @channels = Channel.in_category(@submission.category_id).all(:order => "name asc")
  end

  def update
    @submission = UserSubmission.find(params[:id])
    @submission.update_attributes(params[:user_submission])
    @submission.save

    redirect_to :action => :index
  end

    private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
end
