class FriendLinkingRequest < ActiveRecord::Base
  belongs_to :user
  
  serialize :friend_ids
  
  def self.register(*args)
    params = args.extract_options!
    
    if params[:user] and params[:friends]
      request = FriendLinkingRequest.create(:user_id => params[:user].id, :friend_ids => params[:friends].collect{|u| u.facebook_id})
      Job.enqueue(:type => JobType.find_by_name('friend_linking'), :processable => request)
    end
  end
  
  def find_and_follow_friends!
    if self.user and self.friend_ids
      self.friend_ids.each do |facebook_id|
        if facebook_account = FacebookAccount.find(:first, :conditions => {:facebook_user_id => facebook_id})
          if Friendship.count(:all, :conditions => {:user_id => self.user_id, :friend_id => facebook_account.user_id}) == 0
            friendship = Friendship.new
            friendship.user_id    = self.user_id
            friendship.friend_id  = facebook_account.user_id
            friendship.silent     = true
            friendship.save
          end
          
          if Friendship.count(:all, :conditions => {:user_id => facebook_account.user_id, :friend_id => self.user_id}) == 0
            friendship = Friendship.new
            friendship.user_id    = facebook_account.user_id
            friendship.friend_id  = self.user_id
            friendship.silent     = true
            friendship.save
          end
        end
      end
    end
  end
end
