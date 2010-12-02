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

    redirect_to :action => :index
  end

  def decline
    @submission = UserSubmission.find(params[:id])
    @submission.decline!(logged_in_user)
    
    redirect_to :action => :index
  end

  def edit
    @submission = UserSubmission.find(params[:id])
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
