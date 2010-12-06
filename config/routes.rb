ActionController::Routing::Routes.draw do |map|
  # authentication
  map.connect 'login',                    :controller => 'authentication', :action => 'login'
  map.connect 'logout',                   :controller => 'authentication', :action => 'logout'
  map.connect 'authentication/:action',   :controller => 'authentication'
  
  map.connect 'home',                     :controller => 'videos', :action => 'home'

  # pages
  map.connect 'about',              :controller => 'pages', :action => 'about'
  map.connect 'contact',            :controller => 'pages', :action => 'contact'
  map.connect 'faq',                :controller => 'pages', :action => 'faq'
  map.connect 'tour',               :controller => 'pages', :action => 'tour'
  map.connect 'tour-video',         :controller => 'pages', :action => 'tour_video'
  map.connect 'privacy',            :controller => 'pages', :action => 'privacy'
  map.connect 'terms-of-use',       :controller => 'pages', :action => 'terms_of_use'
  map.connect 'pages/:action',      :controller => 'pages'

  # registration
  map.connect 'register',             :controller => 'registration', :action => 'register'
  map.connect 'setup/services',       :controller => 'registration', :action => 'setup_services'
  map.connect 'setup/profile',        :controller => 'registration', :action => 'setup_profile'
  map.connect 'setup/suggestions',    :controller => 'registration', :action => 'setup_suggestions'
  map.connect 'setup/friends',        :controller => 'registration', :action => 'setup_friends'
  map.connect 'setup/friends/invite', :controller => 'registration', :action => 'invite_friends'
  map.connect 'registration/:action', :controller => 'registration'
  
  #me
  map.connect 'my-subscriptions', :controller => 'users', :action => 'my_subscriptions'
  map.connect 'my-subscriptions/channels', :controller => 'users', :action => 'my_subscriptions_channels'
  map.connect 'my-submissions', :controller => 'user_submissions', :action => 'index'
  map.connect 'my-submissions/accepted', :controller => 'user_submissions', :action => 'accepted'
  map.connect 'my-submissions/declined', :controller => 'user_submissions', :action => 'declined'
  map.connect 'my-submissions/create', :controller => 'user_submissions', :action => 'create'
  map.connect 'my-submissions/channels', :controller => 'user_submissions', :action => 'channels'

  # settings
  map.connect 'settings/activity/group',    :controller => 'settings', :action => 'group_activity'
  map.connect 'settings/activity/ungroup',  :controller => 'settings', :action => 'ungroup_activity'
  map.connect 'settings/:action',           :controller => 'settings'
 
  # channels
  map.connect 'channels/:action',   :controller => 'channels'

  # search
  map.connect 'search/:action',     :controller => 'search'
  # comments
  map.connect 'comments/:action',   :controller => 'comments'

  # subdomain routes
  map.root :controller => 'videos', :action => 'home', :conditions => { :root_only => true }
  map.connect '/', :controller => 'videos', :action => 'category', :category => 'television-shows', :conditions => { :subdomain => "tv" }
  map.connect '/channels', :controller => 'channels', :action => 'index', :category => 'television-shows', :conditions => { :subdomain => "tv" }
  map.connect '/:id/discuss', :controller => 'videos', :action => 'discuss', :conditions => { :subdomain => "tv" }
  map.connect '/:user', :controller => 'channels', :category => 'television-shows', :action => 'show', :channel => 'channel', :conditions => { :subdomain => "tv" }

  map.connect '/', :controller => 'videos', :action => 'category', :category => 'movies-previews-trailers', :conditions => { :subdomain => "movies" }
  map.connect '/channels', :controller => 'channels', :action => 'index', :category => 'movies-previews-trailers', :conditions => { :subdomain => "movies" }
  map.connect '/:id/discuss', :controller => 'videos', :action => 'discuss', :conditions => { :subdomain => "movies" }
  map.connect '/:user', :controller => 'channels', :action => 'show', :category => 'movies-previews-trailers', :channel => 'channel', :conditions => { :subdomain => "movies" }
# videos
  map.connect 'v/:id',                        :controller => 'videos', :action => 'follow'
  map.connect ':id/discuss',                  :controller => 'videos', :action => 'discuss' 
  map.connect ':id/watch',                    :controller => 'videos', :action => 'watch'
  map.connect ':id/like',                     :controller => 'videos', :action => 'like'
  map.connect ':id/dislike',                  :controller => 'videos', :action => 'dislike'
  map.connect ':id/unlike',                   :controller => 'videos', :action => 'unlike'
  map.connect ':id/comment',                  :controller => 'videos', :action => 'comment'
  map.connect ':id/share',                    :controller => 'videos', :action => 'share'
  #legacy routes
  map.connect 'all/newest',               :controller => 'redirections', :action => 'all_newest'
  map.connect 'all/popular',              :controller => 'redirections', :action => 'all_popular'
  map.connect ':category/newest',         :controller => 'redirections', :action => 'category_newest'
  map.connect ':category/popular',        :controller => 'redirections', :action => 'category_popular'
  map.connect 'friends',                  :controller => 'redirections', :action => 'friends'
  map.connect 'all/newest/tagged',        :controller => 'redirections', :action => 'index_newest_tagged'
  map.connect 'all/popular/tagged',       :controller => 'redirections', :action => 'index_popular_tagged'
  map.connect ':category/newest/tagged',  :controller => 'redirections', :action => 'category_newest_tagged'
  map.connect ':category/popular/tagged', :controller => 'redirections', :action => 'category_popular_tagged'

  map.connect ':user',                    :controller => 'redirections', :action => 'user'
  
  map.connect 'all/newest.rss',           :controller => 'redirections', :action => 'newest_rss'
  map.connect 'all/popular.rss',          :controller => 'redirections', :action => 'popular_rss'

  map.connect 'submit/:anything',         :controller => 'redirections', :action => 'submit'
 
  map.connect ':id/activity',             :controller => 'redirections', :action => 'activity'
  map.connect ':id/activity.rss',         :controller => 'redirections', :action => 'activity'
  map.connect ':id/comments',             :controller => 'redirections', :action => 'comments'
  map.connect ':id/follow',               :controller => 'redirections', :action => 'follow'
  map.connect ':id/unfollow',             :controller => 'redirections', :action => 'unfollow'
  map.connect ':id/follows',              :controller => 'redirections', :action => 'follows'
  map.connect ':id/followers',            :controller => 'redirections', :action => 'followers'
  map.connect ':id/friends',              :controller => 'redirections', :action => 'friends'
  map.connect ':id/subscriptions',        :controller => 'redirections', :action => 'subscriptions'

  map.connect 'tags',                     :controller => 'redirections', :action => 'tags'
  map.connect 'tags.rss',                 :controller => 'redirections', :action => 'tags_rss'
  map.connect 'tags/:q',                  :controller => 'redirections', :action => 'tags_q'
  map.connect 'tags/:q.rss',              :controller => 'redirections', :action => 'tags_q_rss'
  
  
  
  

  # administration areas
  map.connect 'admin/overview/:action',     :controller => 'admin/overview'
  map.connect 'admin/channels/:action',     :controller => 'admin/channels'
  map.connect 'admin/comments/:action',     :controller => 'admin/comments'
  map.connect 'admin/import/:action',       :controller => 'admin/import'
  map.connect 'admin/likes/:action',        :controller => 'admin/likes'
  map.connect 'admin/dislikes/:action',        :controller => 'admin/dislikes'
  map.connect 'admin/parameters/:action',   :controller => 'admin/parameters'
  map.connect 'admin/statistics/:action',   :controller => 'admin/statistics'
  map.connect 'admin/suggestions/:action',  :controller => 'admin/suggestions'
  map.connect 'admin/users/:action',        :controller => 'admin/users'
  map.connect 'admin/videos/:action',       :controller => 'admin/videos'
  map.connect 'admin/searches/:action',       :controller => 'admin/searches'

  map.connect 'admin/submissions/new',      :controller => 'admin/submissions', :action => 'new'
  map.connect 'admin/submissions/get-channels',      :controller => 'admin/submissions', :action => 'get_channels'
  map.connect 'admin/submissions',          :controller => 'admin/submissions', :action => 'create'
  map.connect 'admin/user_submissions/:action',          :controller => 'admin/user_submissions'
  
  # nested administration areas
  map.connect 'admin/channels/:channel_id/feeds/:action/:id', :controller => 'admin/feeds'
  
    
  
  

  map.connect 'topics/:category.rss',         :controller => 'videos', :action => 'category', :format => "rss"
  map.connect 'topics/:category/channels',    :controller => 'channels', :action => 'index'
  map.connect 'topics/:category',             :controller => 'videos', :action => 'category'
  map.connect 'topics',                       :controller => 'videos', :action => 'index'
  map.connect 'topics.rss',                   :controller => 'videos', :action => 'index', :format => "rss"
  map.connect ':category/:channel',           :controller => 'channels', :action => 'show'
  map.connect 'subscriptions',                :controller => 'videos', :action => 'subscriptions'
  
  map.connect 'videos/:action',     :controller => 'videos'

  # news items
  map.connect 'news_items/:action', :controller => 'news_items'
  
 
  
  # users
  map.connect ':id/digest',         :controller => 'users', :action => 'digest'
  map.connect 'members/:action',    :controller => 'users'
  
   
  # inviter
  map.connect 'invitation/:action', :controller => 'invitation'
  
  # twitter
  map.connect 'twitter/:action',    :controller => 'twitter'
  
  # facebook connect
  map.connect 'fb_callback',        :controller => 'facebook', :action => 'fb_callback'
  map.connect 'facebook/:action',   :controller => 'facebook'
   
  # named paths
  map.user_channel ':user/channel', :controller => 'channels', :action => 'show', :channel => "channel"
  map.channel ':user/:channel',                 :controller => 'channels', :action => 'show'
  map.channel_rss ':user/:channel.rss',         :controller => 'channels', :action => 'show', :format => 'rss'
  map.subscribers ':user/:channel/subscribers', :controller => 'channels', :action => 'subscribers'
  
  map.facebook_connect 'facebook/connect',      :controller => 'facebook', :action => 'connect'
  
  # generic routes
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end
