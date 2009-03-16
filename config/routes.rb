ActionController::Routing::Routes.draw do |map|
  # authentication
  map.connect 'login',              :controller => 'authentication', :action => 'login'
  map.connect 'logout',             :controller => 'authentication', :action => 'logout'
  
  
  # registration
  map.connect 'register',           :controller => 'registration', :action => 'register'
  map.connect 'setup/services',     :controller => 'registration', :action => 'setup_services'
  map.connect 'setup/profile',      :controller => 'registration', :action => 'setup_profile'
  
  
  # videos
  map.connect 'all/newest',         :controller => 'videos', :action => 'index', :popular => false
  map.connect 'all/popular',        :controller => 'videos', :action => 'index', :popular => true
  map.connect ':category/newest',   :controller => 'videos', :action => 'category', :popular => false
  map.connect ':category/popular',  :controller => 'videos', :action => 'category', :popular => true
  map.connect 'friends',            :controller => 'videos', :action => 'friends'
  map.connect 'subscriptions',      :controller => 'videos', :action => 'subscriptions'
  
  map.connect 'v/:id',              :controller => 'videos', :action => 'follow'
  map.connect ':id/discuss',        :controller => 'videos', :action => 'discuss'
  map.connect ':id/watch',          :controller => 'videos', :action => 'watch'
  map.connect ':id/like',           :controller => 'videos', :action => 'like'
  map.connect ':id/unlike',         :controller => 'videos', :action => 'unlike'
  map.connect ':id/comment',        :controller => 'videos', :action => 'comment'
  
  map.connect 'videos/:action',     :controller => 'videos'
  
  
  # comments
  map.connect 'comments/:action',   :controller => 'comments'
  
  
  # users
  map.connect ':id/activity',       :controller => 'users', :action => 'activity'
  map.connect ':id/profile',        :controller => 'users', :action => 'profile'
  map.connect ':id/comments',       :controller => 'users', :action => 'comments'
  map.connect ':id/follows',        :controller => 'users', :action => 'follows'
  map.connect ':id/followers',      :controller => 'users', :action => 'followers'
  map.connect ':id/friends',        :controller => 'users', :action => 'friends'
  map.connect ':id/subscriptions',  :controller => 'users', :action => 'subscriptions'
  map.connect 'members/:action',    :controller => 'users'
  
  
  # channels
  map.connect 'channels/:action',   :controller => 'channels'
  
  
  # search
  map.connect 'search/:action',     :controller => 'search'
  
  
  # pages
  map.connect 'buttons',            :controller => 'pages', :action => 'buttons'
  map.connect 'contact',            :controller => 'pages', :action => 'contact'
  map.connect 'how',                :controller => 'pages', :action => 'how_gawkk_works'
  map.connect 'privacy',            :controller => 'pages', :action => 'privacy'
  map.connect 'report-bug',         :controller => 'pages', :action => 'report_bug'
  map.connect 'rss',                :controller => 'pages', :action => 'rss'
  map.connect 'share',              :controller => 'pages', :action => 'share'
  map.connect 'terms-of-use',       :controller => 'pages', :action => 'terms_of_use'
  map.connect 'tour',               :controller => 'pages', :action => 'tour'
  map.connect 'faq',                :controller => 'pages', :action => 'faq'
  map.connect 'jobs',               :controller => 'pages', :action => 'jobs'
  map.connect 'pages/:action',      :controller => 'pages'
  
  
  # named paths
  map.channel ':user/:channel',     :controller => 'channels', :action => 'show'
  
  
  # front page
  map.root :controller => 'videos', :action => 'friends'
  
  # generic routes
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
  map.connect ':id', :controller => 'users', :action => 'activity'
  
  # named path for building the generic user route
  map.user ':id', :controller => 'users', :action => 'activity'
end
