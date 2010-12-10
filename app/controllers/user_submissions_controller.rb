
class UserSubmissionsController < ApplicationController
  around_filter :ensure_logged_in_user
  layout 'page'
  def index
    pitch(:title => "Your Open Submissions")
    set_title("Your Open Submissions")
    @categories = Category.all(:order => "name asc")
    @channels = Channel.in_category(@categories[0].id).all(:order => "name asc")

    @submission = UserSubmission.new
    @submissions = UserSubmission.find(:all, :conditions => { :user_id => logged_in_user.id, :status => 1 }, :order => "created_at desc")
  end

  def create
    text = params[:user_submission][:url]

    if text.blank? || text == 'Video URL'
      flash[:notice] = "Please enter an url" 
      redirect_to :action => :index and return
    end

    begin
      urls = params[:user_submission][:url].split ','
      urls.each do |u|
        @submission = UserSubmission.new(params[:user_submission])
        @submission.url = u
        if @submission.load_title
          @submission.user_id = logged_in_user.id
          @submission.save
        end
      end
      
      flash[:notice] = "Your video has been submitted"
      redirect_to :action => :index
    rescue
      @submission = UserSubmission.new
      flash[:notice] = "There was an error with your submission"
      redirect_to :action => :index and return
    end
  end

  def declined
    pitch(:title => "Your Declined Submissions")
    set_title("Your Declined Submissions")
    @categories = Category.all(:order => "name asc")
    @channels = Channel.in_category(@categories[0].id).all(:order => "name asc")

    @submission = UserSubmission.new
    @submissions = UserSubmission.find(:all, :conditions => { :user_id => logged_in_user.id, :status => 3 }, :order => "processed_at desc")
  end

  def accepted
    pitch(:title => "Your Accepted Submissions")
    set_title("Your Accepted Submissions")
   @categories = Category.all(:order => "name asc")
    @channels = Channel.in_category(@categories[0].id).all(:order => "name asc")
    @submission = UserSubmission.new
    @submissions = UserSubmission.find(:all, :conditions => { :user_id => logged_in_user.id, :status => 2 }, :order => "processed_at desc", :include => :video)
  end

  def channels
    @channels = Channel.in_category(params[:category_id]).all(:order => "name asc")
    render :layout => false
  end

   private
  def ensure_logged_in_user
    if user_logged_in?
      yield
    else
      render :nothing => true
    end
  end

end
