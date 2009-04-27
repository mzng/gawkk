class CommentsController < ApplicationController
  around_filter :ensure_logged_in_user, :only => [:like, :comment]
  
  def create
    @comment = Comment.new(params[:comment])
    
    if user_logged_in?
      @comment.user_id = logged_in_user.id
      @comment.twitter_username = logged_in_user.twitter_account.username if (params[:tweet] and params[:tweet][:it] == '1' and logged_in_user.auto_tweet?)
      @comment.save

      spawn do
        invitees = Array.new

        if params["friend_for_#{@comment.commentable_id}"]
          params["friend_for_#{@comment.commentable_id}"].keys.each do |user_id|
            if user = User.find(user_id)
              invitees << user.email
            end
          end
        end

        if params["contact_for_#{@comment.commentable_id}"]
          params["contact_for_#{@comment.commentable_id}"].keys.each do |contact_id|
            if contact = Contact.find(contact_id)
              invitees << contact.email
            end
          end
        end

        if params["email_for_#{@comment.commentable_id}"]
          params["email_for_#{@comment.commentable_id}"].keys.each do |email|
            if email[/^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/]
              invitees << email
              Contact.create :user_id => @comment.user_id, :email => email
            end
          end
        end

        invitees.each do |email|
          details = Hash.new
          details[:sender] = @comment.user
          details[:recipient_email] = email
          details[:video] = @comment.commentable
          details[:thread_id] = @comment.thread_id

          DiscussionMailer.deliver_invitation(details)
        end

        if params[:tweet][:it] == '1' and logged_in_user.auto_tweet?
          Tweet.report('make_a_comment', logged_in_user, @comment)
        end
      end
    else
      session[:actionable] = @comment
      render :template => 'authentication/login'
    end
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
