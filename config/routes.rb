ActionController::Routing::Routes.draw do |map|
  # authentication
  map.connect 'login',                    :controller => 'authentication', :action => 'login'
  map.connect 'logout',                   :controller => 'authentication', :action => 'logout'
  map.connect 'authentication/:action',   :controller => 'authentication'
  
  
  # administration areas
  map.connect 'admin/overview/:action',     :controller => 'admin/overview'
  map.connect 'admin/channels/:action',     :controller => 'admin/channels'
  map.connect 'admin/comments/:action',     :controller => 'admin/comments'
  map.connect 'admin/import/:action',       :controller => 'admin/import'
  map.connect 'admin/likes/:action',        :controller => 'admin/likes'
  map.connect 'admin/parameters/:action',   :controller => 'admin/parameters'
  map.connect 'admin/statistics/:action',   :controller => 'admin/statistics'
  map.connect 'admin/suggestions/:action',  :controller => 'admin/suggestions'
  map.connect 'admin/users/:action',        :controller => 'admin/users'
  map.connect 'admin/videos/:action',       :controller => 'admin/videos'
  
  # nested administration areas
  map.connect 'admin/channels/:channel_id/feeds/:action/:id', :controller => 'admin/feeds'
  
  
  # registration
  map.connect 'register',             :controller => 'registration', :action => 'register'
  map.connect 'setup/services',       :controller => 'registration', :action => 'setup_services'
  map.connect 'setup/profile',        :controller => 'registration', :action => 'setup_profile'
  map.connect 'setup/suggestions',    :controller => 'registration', :action => 'setup_suggestions'
  map.connect 'setup/friends',        :controller => 'registration', :action => 'setup_friends'
  map.connect 'setup/friends/invite', :controller => 'registration', :action => 'invite_friends'
  map.connect 'registration/:action', :controller => 'registration'
  
  
  # settings
  map.connect 'settings/activity/group',    :controller => 'settings', :action => 'group_activity'
  map.connect 'settings/activity/ungroup',  :controller => 'settings', :action => 'ungroup_activity'
  map.connect 'settings/:action',           :controller => 'settings'
  
  
  # submit
  map.connect 'submit/:action',     :controller => 'submit'
  
  
  # videos
  map.connect 'home',               :controller => 'videos', :action => 'home'
  map.connect 'friends',            :controller => 'videos', :action => 'friends'
  map.connect 'all/newest',         :controller => 'videos', :action => 'index', :popular => false
  map.connect 'all/popular',        :controller => 'videos', :action => 'index', :popular => true
  map.connect ':category/newest',   :controller => 'videos', :action => 'category', :popular => false
  map.connect ':category/popular',  :controller => 'videos', :action => 'category', :popular => true
  map.connect 'subscriptions',      :controller => 'videos', :action => 'subscriptions'
  
  map.connect 'v/:id',              :controller => 'videos', :action => 'follow'
  map.connect ':id/discuss',        :controller => 'videos', :action => 'discuss'
  map.connect ':id/watch',          :controller => 'videos', :action => 'watch'
  map.connect ':id/like',           :controller => 'videos', :action => 'like'
  map.connect ':id/unlike',         :controller => 'videos', :action => 'unlike'
  map.connect ':id/comment',        :controller => 'videos', :action => 'comment'
  map.connect ':id/share',          :controller => 'videos', :action => 'share'
  
  map.connect 'all/newest/tagged',        :controller => 'videos', :action => 'index', :popular => false, :tagged => true
  map.connect 'all/popular/tagged',       :controller => 'videos', :action => 'index', :popular => true, :tagged => true
  map.connect ':category/newest/tagged',  :controller => 'videos', :action => 'category', :popular => false, :tagged => true
  map.connect ':category/popular/tagged', :controller => 'videos', :action => 'category', :popular => true, :tagged => true
  
  map.connect 'all/newest.rss',           :controller => 'videos', :action => 'index', :popular => false, :format => 'rss'
  map.connect 'all/popular.rss',          :controller => 'videos', :action => 'index', :popular => true, :format => 'rss'
  map.connect ':category/newest.rss',     :controller => 'videos', :action => 'category', :popular => false, :format => 'rss'
  map.connect ':category/popular.rss',    :controller => 'videos', :action => 'category', :popular => true, :format => 'rss'
  
  map.connect 'videos/:action',     :controller => 'videos'
  
  
  # news items
  map.connect 'news_items/:action', :controller => 'news_items'
  
  
  # comments
  map.connect 'comments/:action',   :controller => 'comments'
  
  
  # users
  map.connect ':id/activity',       :controller => 'users', :action => 'activity'
  map.connect ':id/comments',       :controller => 'users', :action => 'comments'
  map.connect ':id/follows',        :controller => 'users', :action => 'follows'
  map.connect ':id/followers',      :controller => 'users', :action => 'followers'
  map.connect ':id/friends',        :controller => 'users', :action => 'friends'
  map.connect ':id/subscriptions',  :controller => 'users', :action => 'subscriptions'
  map.connect ':id/digest',         :controller => 'users', :action => 'digest'
  
  map.connect ':id/follow',         :controller => 'users', :action => 'follow'
  map.connect ':id/unfollow',       :controller => 'users', :action => 'unfollow'
  
  map.connect ':id/activity.rss',   :controller => 'users', :action => 'activity', :format => 'rss'
  
  map.connect 'members/:action',    :controller => 'users'
  
  
  # channels
  map.connect 'channels/:action',   :controller => 'channels'
  
  
  # inviter
  map.connect 'invitation/:action', :controller => 'invitation'
  
  
  # twitter
  map.connect 'twitter/:action',    :controller => 'twitter'
  
  
  # facebook connect
  map.connect 'fb_callback',        :controller => 'facebook', :action => 'fb_callback'
  map.connect 'facebook/:action',   :controller => 'facebook'
  
  
  # search
  map.connect 'search/:action',     :controller => 'search'
  
  
  # tags
  map.connect 'tags/:q',            :controller => 'tags'
  map.connect 'tags/:q.rss',        :controller => 'tags', :format => 'rss'
  
  
  # pages
  map.connect 'about',              :controller => 'pages', :action => 'about'
  map.connect 'contact',            :controller => 'pages', :action => 'contact'
  map.connect 'faq',                :controller => 'pages', :action => 'faq'
  map.connect 'tour',               :controller => 'pages', :action => 'tour'
  map.connect 'tour-video',         :controller => 'pages', :action => 'tour_video'
  map.connect 'privacy',            :controller => 'pages', :action => 'privacy'
  map.connect 'terms-of-use',       :controller => 'pages', :action => 'terms_of_use'
  map.connect 'pages/:action',      :controller => 'pages'
  
  
  # named paths
  map.channel ':user/:channel',                 :controller => 'channels', :action => 'show'
  map.channel_rss ':user/:channel.rss',         :controller => 'channels', :action => 'show', :format => 'rss'
  map.subscribers ':user/:channel/subscribers', :controller => 'channels', :action => 'subscribers'
  
  map.facebook_connect 'facebook/connect',      :controller => 'facebook', :action => 'connect'
  
  
  # front page
  map.root :controller => 'videos', :action => 'home'
  
  # generic routes
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':id', :controller => 'users', :action => 'activity'
  
  # named path for building the generic user route
  map.user ':id', :controller => 'users', :action => 'activity'
end
