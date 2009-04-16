# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20090416162413) do

  create_table "age_ranges", :force => true do |t|
    t.integer "position"
    t.string  "range",    :null => false
  end

  create_table "blacklisted_domains", :force => true do |t|
    t.string  "domain",                          :null => false
    t.boolean "submit_frame", :default => false, :null => false
    t.boolean "watch_frame",  :default => false, :null => false
    t.boolean "video_embed",  :default => false, :null => false
  end

  create_table "blacklisted_emails", :force => true do |t|
    t.string   "auth_code"
    t.string   "email"
    t.datetime "created_at"
  end

  create_table "categories", :force => true do |t|
    t.string  "name"
    t.string  "slug"
    t.integer "position"
    t.integer "threshold_type_id"
    t.integer "threshold"
    t.boolean "allowed_on_front_page",       :default => true, :null => false
    t.integer "target_number_of_promotions", :default => 0,    :null => false
    t.integer "earliest_popular_video_id"
    t.integer "earliest_video_id"
    t.integer "latest_popular_video_id"
    t.integer "latest_video_id"
    t.string  "thumbnail"
  end

  add_index "categories", ["threshold_type_id"], :name => "threshold_type_id"
  add_index "categories", ["earliest_popular_video_id"], :name => "earliest_popular_video_id"
  add_index "categories", ["earliest_video_id"], :name => "earliest_video_id"
  add_index "categories", ["latest_popular_video_id"], :name => "latest_popular_video_id"
  add_index "categories", ["latest_video_id"], :name => "latest_video_id"

  create_table "channels", :force => true do |t|
    t.string   "name"
    t.string   "slug"
    t.text     "description",                            :null => false
    t.integer  "user_id"
    t.boolean  "featured",            :default => false, :null => false
    t.datetime "created_at"
    t.integer  "saves_count",         :default => 0,     :null => false
    t.integer  "views_count",         :default => 0,     :null => false
    t.integer  "subscriptions_count", :default => 0,     :null => false
    t.string   "category_ids",                           :null => false
    t.boolean  "user_owned",          :default => true
    t.datetime "last_save_at"
    t.text     "keywords",                               :null => false
    t.integer  "earliest_video_id"
    t.integer  "latest_video_id"
    t.boolean  "mature",              :default => false, :null => false
    t.boolean  "comparable",          :default => false, :null => false
    t.integer  "comments_count",      :default => 0,     :null => false
  end

  add_index "channels", ["user_id"], :name => "newfk"
  add_index "channels", ["earliest_video_id"], :name => "earliest_video_id"
  add_index "channels", ["latest_video_id"], :name => "latest_video_id"

  create_table "comments", :force => true do |t|
    t.text     "body"
    t.integer  "user_id"
    t.datetime "created_at"
    t.string   "commentable_type"
    t.integer  "commentable_id"
    t.string   "thread_id"
    t.string   "twitter_username"
  end

  add_index "comments", ["user_id"], :name => "user_id"

  create_table "contacts", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "email"
    t.datetime "created_at"
  end

  add_index "contacts", ["user_id"], :name => "user_id"

  create_table "deleted_videos", :force => true do |t|
    t.string   "name"
    t.text     "url"
    t.text     "truveo_url"
    t.datetime "deleted_at"
  end

  create_table "feed_importer_reports", :force => true do |t|
    t.integer  "feed_id"
    t.integer  "videos_count",             :default => 0,     :null => false
    t.boolean  "completed_successfully",   :default => false
    t.datetime "created_at"
    t.integer  "items_in_feed",            :default => 0,     :null => false
    t.integer  "minutes_until_next_fetch", :default => 0,     :null => false
    t.boolean  "scheduled",                :default => false, :null => false
    t.integer  "thumbnail_count",          :default => 0,     :null => false
    t.boolean  "embed_code_from_rss",      :default => false, :null => false
  end

  add_index "feed_importer_reports", ["feed_id"], :name => "feed_id"

  create_table "feeds", :force => true do |t|
    t.integer  "category_id"
    t.integer  "owned_by_id"
    t.string   "url"
    t.boolean  "active",                 :default => false, :null => false
    t.integer  "channel_videos_count"
    t.datetime "last_video_imported_at"
    t.boolean  "locked",                 :default => false, :null => false
    t.boolean  "keep_fresh",             :default => false, :null => false
    t.datetime "last_accessed_at"
    t.integer  "playlist_id"
  end

  add_index "feeds", ["category_id"], :name => "category_id"
  add_index "feeds", ["owned_by_id"], :name => "owned_by_id"
  add_index "feeds", ["playlist_id"], :name => "playlist_id"

  create_table "flag_types", :force => true do |t|
    t.string  "name"
    t.integer "position",                           :null => false
    t.string  "highlight_color"
    t.boolean "deleted",         :default => false, :null => false
  end

  create_table "flags", :force => true do |t|
    t.integer  "flag_type_id"
    t.integer  "user_id"
    t.integer  "video_id"
    t.datetime "created_at"
  end

  add_index "flags", ["flag_type_id"], :name => "flag_type_id"
  add_index "flags", ["user_id"], :name => "user_id"
  add_index "flags", ["video_id"], :name => "video_id"

  create_table "friendships", :force => true do |t|
    t.integer  "user_id"
    t.integer  "friend_id"
    t.datetime "created_at"
    t.string   "auth_code"
    t.boolean  "mutual",     :default => false, :null => false
  end

  add_index "friendships", ["user_id"], :name => "user_id"
  add_index "friendships", ["friend_id"], :name => "friend_id"

  create_table "import_request_statuses", :force => true do |t|
    t.string "name"
  end

  create_table "import_requests", :force => true do |t|
    t.integer  "import_request_status_id"
    t.integer  "channel_id"
    t.integer  "videos_count"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "import_requests", ["import_request_status_id"], :name => "import_request_status_id"
  add_index "import_requests", ["channel_id"], :name => "channel_id"

  create_table "invitations", :force => true do |t|
    t.integer  "host_id"
    t.string   "invitee_email"
    t.text     "message"
    t.datetime "invited_at"
    t.boolean  "accepted",      :default => false, :null => false
    t.integer  "invitee_id"
    t.datetime "accepted_at"
    t.datetime "queued_at"
    t.boolean  "for_quiz",      :default => false, :null => false
  end

  add_index "invitations", ["host_id"], :name => "host_id"
  add_index "invitations", ["invitee_id"], :name => "invitee_id"

  create_table "job_categories", :force => true do |t|
    t.integer "position"
    t.string  "name",     :null => false
  end

  create_table "jobs", :force => true do |t|
    t.integer "job_category_id"
    t.integer "position"
    t.string  "title",           :null => false
    t.text    "description",     :null => false
  end

  add_index "jobs", ["job_category_id"], :name => "job_category_id"

  create_table "likes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "video_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "likes", ["user_id"], :name => "user_id"
  add_index "likes", ["video_id"], :name => "video_id"

  create_table "message_types", :force => true do |t|
    t.string "name"
  end

  create_table "messages", :force => true do |t|
    t.string   "thread_id"
    t.integer  "sender_id"
    t.string   "sender_email"
    t.integer  "receiver_id"
    t.string   "receiver_email"
    t.string   "shareable_type"
    t.integer  "shareable_id"
    t.text     "body"
    t.boolean  "read",                 :default => false, :null => false
    t.boolean  "archived_by_sender",   :default => false, :null => false
    t.boolean  "archived_by_receiver", :default => false, :null => false
    t.datetime "created_at"
    t.integer  "message_type_id"
  end

  add_index "messages", ["sender_id"], :name => "sender_id"
  add_index "messages", ["receiver_id"], :name => "receiver_id"
  add_index "messages", ["message_type_id"], :name => "message_type_id"

  create_table "news_item_types", :force => true do |t|
    t.string "name"
    t.text   "template"
    t.string "kind",     :null => false
  end

  create_table "news_items", :force => true do |t|
    t.integer  "news_item_type_id"
    t.integer  "user_id"
    t.string   "reportable_type"
    t.integer  "reportable_id"
    t.text     "message"
    t.datetime "created_at"
    t.boolean  "hidden",            :default => false, :null => false
    t.boolean  "mature",            :default => false, :null => false
    t.string   "thread_id"
  end

  add_index "news_items", ["news_item_type_id"], :name => "news_item_type_id"
  add_index "news_items", ["user_id"], :name => "user_id"

  create_table "parameters", :force => true do |t|
    t.string "name"
    t.string "value"
  end

  create_table "playlist_items", :force => true do |t|
    t.integer  "playlist_id"
    t.integer  "position"
    t.integer  "video_id"
    t.datetime "created_at"
  end

  add_index "playlist_items", ["playlist_id"], :name => "playlist_id"
  add_index "playlist_items", ["video_id"], :name => "video_id"

  create_table "playlists", :force => true do |t|
    t.integer  "user_id"
    t.integer  "channel_id"
    t.string   "name"
    t.string   "slug"
    t.datetime "created_at"
    t.integer  "views_count", :default => 0, :null => false
  end

  add_index "playlists", ["user_id"], :name => "user_id"
  add_index "playlists", ["channel_id"], :name => "channel_id"

  create_table "promotion_schedules", :force => true do |t|
    t.integer "category_id"
    t.integer "hour",                 :null => false
    t.integer "number_of_promotions", :null => false
  end

  add_index "promotion_schedules", ["category_id"], :name => "category_id"

  create_table "question_categories", :force => true do |t|
    t.integer "position"
    t.string  "name",     :null => false
  end

  create_table "questions", :force => true do |t|
    t.integer "question_category_id"
    t.integer "position"
    t.string  "title",                :null => false
    t.text    "answer",               :null => false
  end

  add_index "questions", ["question_category_id"], :name => "question_category_id"

  create_table "ratings", :force => true do |t|
    t.integer  "user_id"
    t.integer  "channel_id"
    t.integer  "value",      :limit => 10, :precision => 10, :scale => 0
    t.datetime "created_at"
  end

  add_index "ratings", ["user_id"], :name => "user_id"
  add_index "ratings", ["channel_id"], :name => "channel_id"

  create_table "saved_videos", :force => true do |t|
    t.integer  "video_id"
    t.datetime "created_at"
    t.integer  "channel_id"
    t.text     "next_videos"
  end

  add_index "saved_videos", ["video_id"], :name => "saves_ibfk_1"
  add_index "saved_videos", ["channel_id", "created_at"], :name => "channel_id"

  create_table "search_types", :force => true do |t|
    t.string "name"
  end

  create_table "searches", :force => true do |t|
    t.integer  "search_type_id"
    t.string   "query"
    t.integer  "user_id"
    t.datetime "created_at"
  end

  add_index "searches", ["search_type_id"], :name => "search_type_id"
  add_index "searches", ["user_id"], :name => "user_id"

  create_table "subscriptions", :force => true do |t|
    t.integer  "channel_id"
    t.integer  "user_id"
    t.datetime "created_at"
  end

  add_index "subscriptions", ["channel_id"], :name => "channel_id"
  add_index "subscriptions", ["user_id"], :name => "user_id"

  create_table "suggestions", :force => true do |t|
    t.integer  "user_id"
    t.integer  "channel_id"
    t.string   "suggestion_type"
    t.string   "url"
    t.boolean  "processed",       :default => false, :null => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "suggestions", ["user_id"], :name => "user_id"
  add_index "suggestions", ["channel_id"], :name => "channel_id"

  create_table "tweet_types", :force => true do |t|
    t.string "name"
    t.text   "template"
  end

  create_table "tweets", :force => true do |t|
    t.integer  "twitter_account_id"
    t.integer  "tweet_type_id"
    t.string   "auth_code"
    t.string   "reportable_type"
    t.integer  "reportable_id"
    t.boolean  "published",          :default => false, :null => false
    t.datetime "created_at"
  end

  add_index "tweets", ["twitter_account_id"], :name => "twitter_account_id"
  add_index "tweets", ["tweet_type_id"], :name => "tweet_type_id"

  create_table "twitter_accounts", :force => true do |t|
    t.integer  "user_id"
    t.string   "username"
    t.string   "password"
    t.boolean  "authenticated", :default => false, :null => false
    t.datetime "created_at"
    t.boolean  "tweet_likes",   :default => true,  :null => false
  end

  add_index "twitter_accounts", ["user_id"], :name => "user_id"

  create_table "users", :force => true do |t|
    t.boolean  "administrator",                             :default => false
    t.string   "username"
    t.string   "hashed_password"
    t.string   "name"
    t.string   "email"
    t.string   "location"
    t.datetime "last_login_at"
    t.datetime "created_at"
    t.boolean  "feed_owner",                                :default => false, :null => false
    t.text     "description"
    t.integer  "comments_count",                            :default => 0,     :null => false
    t.integer  "my_comments_count",                         :default => 0,     :null => false
    t.integer  "videos_count",                              :default => 0,     :null => false
    t.integer  "flags_count",                               :default => 0,     :null => false
    t.integer  "views_count",                               :default => 0,     :null => false
    t.integer  "age_range_id"
    t.string   "youtube_username",                                             :null => false
    t.boolean  "send_digest_emails",                        :default => false, :null => false
    t.string   "email_confirmation_auth_code"
    t.datetime "email_confirmed_at"
    t.string   "password_reset_auth_code"
    t.datetime "password_reset_expires_at"
    t.integer  "friends_version",                           :default => 0,     :null => false
    t.string   "slug"
    t.string   "thumbnail"
    t.string   "salt"
    t.string   "cookie_hash"
    t.string   "sex",                          :limit => 1
    t.string   "zip_code",                     :limit => 5
    t.text     "friends_channels_cache"
    t.text     "subscribed_channels_cache"
    t.boolean  "beta_views",                                :default => false, :null => false
    t.integer  "myspace_id"
    t.boolean  "safe_search",                               :default => true,  :null => false
    t.boolean  "age_verified",                              :default => false, :null => false
    t.boolean  "using_default_friends",                     :default => false, :null => false
    t.boolean  "using_default_subscriptions",               :default => false, :null => false
    t.string   "ad_campaign"
    t.boolean  "category_notice_dismissed",                 :default => false, :null => false
    t.string   "twitter_username"
    t.string   "friendfeed_username"
    t.string   "website_url"
    t.string   "feed_url"
    t.integer  "digest_email_frequency",                    :default => 0,     :null => false
  end

  add_index "users", ["age_range_id"], :name => "age_range_id"

  create_table "videos", :force => true do |t|
    t.integer  "category_id"
    t.string   "name"
    t.string   "slug"
    t.text     "description"
    t.text     "url"
    t.integer  "posted_by_id"
    t.datetime "posted_at"
    t.datetime "promoted_at"
    t.integer  "saves_count",              :default => 0,     :null => false
    t.text     "embed_code",                                  :null => false
    t.integer  "views_count",              :default => 0,     :null => false
    t.integer  "comments_count",           :default => 0,     :null => false
    t.integer  "flags_count",              :default => 0,     :null => false
    t.string   "thumbnail"
    t.text     "swf_url",                                     :null => false
    t.integer  "feed_importer_report_id"
    t.integer  "version",                  :default => 0,     :null => false
    t.integer  "member_saves_count",       :default => 0,     :null => false
    t.text     "truveo_url"
    t.text     "source_domain",                               :null => false
    t.text     "next_videos"
    t.integer  "votes_count",              :default => 0
    t.integer  "member_votes_count",       :default => 0
    t.boolean  "ineligible_for_promotion", :default => false
    t.string   "short_code"
    t.integer  "likes_count",              :default => 0
  end

  add_index "videos", ["posted_by_id"], :name => "posted_by_id"
  add_index "videos", ["feed_importer_report_id"], :name => "feed_importer_report_id"
  add_index "videos", ["slug"], :name => "slug_del"
  add_index "videos", ["category_id", "promoted_at"], :name => "category_id"
  add_index "videos", ["category_id", "posted_at"], :name => "category_id_posted_at"

  create_table "views", :force => true do |t|
    t.integer  "user_id"
    t.string   "viewable_type"
    t.integer  "viewable_id"
    t.text     "current_path"
    t.text     "user_agent"
    t.datetime "created_at"
    t.text     "http_referer"
    t.string   "session_id"
  end

  add_index "views", ["user_id"], :name => "views_ibfk_1"

  create_table "votes", :force => true do |t|
    t.integer  "user_id"
    t.boolean  "feed_owner"
    t.integer  "video_id"
    t.integer  "value"
    t.datetime "created_at"
  end

  add_index "votes", ["user_id"], :name => "user_id"
  add_index "votes", ["video_id"], :name => "video_id"

  create_table "word_lists", :force => true do |t|
    t.string "name"
  end

  create_table "words", :force => true do |t|
    t.integer "word_list_id", :null => false
    t.string  "value"
  end

  add_index "words", ["word_list_id"], :name => "word_list_id"

  create_table "you_tube_categories", :force => true do |t|
    t.string  "name"
    t.integer "category_id"
  end

  add_index "you_tube_categories", ["category_id"], :name => "category_id"

  add_foreign_key "categories", ["earliest_popular_video_id"], "videos", ["id"], :name => "categories_ibfk_2"
  add_foreign_key "categories", ["earliest_video_id"], "videos", ["id"], :name => "categories_ibfk_3"
  add_foreign_key "categories", ["latest_popular_video_id"], "videos", ["id"], :name => "categories_ibfk_4"
  add_foreign_key "categories", ["latest_video_id"], "videos", ["id"], :name => "categories_ibfk_5"

  add_foreign_key "channels", ["earliest_video_id"], "videos", ["id"], :name => "channels_ibfk_1"
  add_foreign_key "channels", ["latest_video_id"], "videos", ["id"], :name => "channels_ibfk_2"
  add_foreign_key "channels", ["user_id"], "users", ["id"], :name => "newfk"

  add_foreign_key "comments", ["user_id"], "users", ["id"], :name => "comments_ibfk_1"

  add_foreign_key "contacts", ["user_id"], "users", ["id"], :name => "contacts_ibfk_1"

  add_foreign_key "feed_importer_reports", ["feed_id"], "feeds", ["id"], :name => "feed_importer_reports_ibfk_1"

  add_foreign_key "feeds", ["category_id"], "categories", ["id"], :name => "feeds_ibfk_1"
  add_foreign_key "feeds", ["owned_by_id"], "users", ["id"], :name => "feeds_ibfk_2"
  add_foreign_key "feeds", ["playlist_id"], "playlists", ["id"], :name => "feeds_ibfk_3"

  add_foreign_key "flags", ["flag_type_id"], "flag_types", ["id"], :name => "flags_ibfk_1"
  add_foreign_key "flags", ["user_id"], "users", ["id"], :name => "flags_ibfk_2"
  add_foreign_key "flags", ["video_id"], "videos", ["id"], :name => "flags_ibfk_3"

  add_foreign_key "friendships", ["user_id"], "users", ["id"], :name => "friendships_ibfk_1"
  add_foreign_key "friendships", ["friend_id"], "users", ["id"], :name => "friendships_ibfk_2"

  add_foreign_key "import_requests", ["import_request_status_id"], "import_request_statuses", ["id"], :name => "import_requests_ibfk_1"
  add_foreign_key "import_requests", ["channel_id"], "channels", ["id"], :name => "import_requests_ibfk_2"

  add_foreign_key "invitations", ["host_id"], "users", ["id"], :name => "invitations_ibfk_1"
  add_foreign_key "invitations", ["invitee_id"], "users", ["id"], :name => "invitations_ibfk_2"

  add_foreign_key "jobs", ["job_category_id"], "job_categories", ["id"], :name => "jobs_ibfk_1"

  add_foreign_key "likes", ["user_id"], "users", ["id"], :name => "likes_ibfk_1"
  add_foreign_key "likes", ["video_id"], "videos", ["id"], :name => "likes_ibfk_2"

  add_foreign_key "messages", ["sender_id"], "users", ["id"], :name => "messages_ibfk_1"
  add_foreign_key "messages", ["receiver_id"], "users", ["id"], :name => "messages_ibfk_2"
  add_foreign_key "messages", ["message_type_id"], "message_types", ["id"], :name => "messages_ibfk_3"

  add_foreign_key "news_items", ["news_item_type_id"], "news_item_types", ["id"], :name => "news_items_ibfk_1"
  add_foreign_key "news_items", ["user_id"], "users", ["id"], :name => "news_items_ibfk_2"

  add_foreign_key "playlist_items", ["playlist_id"], "playlists", ["id"], :name => "playlist_items_ibfk_1"
  add_foreign_key "playlist_items", ["video_id"], "videos", ["id"], :name => "playlist_items_ibfk_2"

  add_foreign_key "playlists", ["user_id"], "users", ["id"], :name => "playlists_ibfk_1"
  add_foreign_key "playlists", ["channel_id"], "channels", ["id"], :name => "playlists_ibfk_2"

  add_foreign_key "promotion_schedules", ["category_id"], "categories", ["id"], :name => "promotion_schedules_ibfk_1"

  add_foreign_key "questions", ["question_category_id"], "question_categories", ["id"], :name => "questions_ibfk_1"

  add_foreign_key "ratings", ["user_id"], "users", ["id"], :name => "ratings_ibfk_1"
  add_foreign_key "ratings", ["channel_id"], "channels", ["id"], :name => "ratings_ibfk_2"

  add_foreign_key "saved_videos", ["video_id"], "videos", ["id"], :name => "saved_videos_ibfk_1"
  add_foreign_key "saved_videos", ["channel_id"], "channels", ["id"], :name => "saved_videos_ibfk_2"

  add_foreign_key "searches", ["search_type_id"], "search_types", ["id"], :name => "searches_ibfk_1"
  add_foreign_key "searches", ["user_id"], "users", ["id"], :name => "searches_ibfk_2"

  add_foreign_key "subscriptions", ["channel_id"], "channels", ["id"], :name => "subscriptions_ibfk_1"
  add_foreign_key "subscriptions", ["user_id"], "users", ["id"], :name => "subscriptions_ibfk_2"

  add_foreign_key "suggestions", ["user_id"], "users", ["id"], :name => "suggestions_ibfk_1"
  add_foreign_key "suggestions", ["channel_id"], "channels", ["id"], :name => "suggestions_ibfk_2"

  add_foreign_key "tweets", ["twitter_account_id"], "twitter_accounts", ["id"], :name => "tweets_ibfk_1"
  add_foreign_key "tweets", ["tweet_type_id"], "tweet_types", ["id"], :name => "tweets_ibfk_2"

  add_foreign_key "twitter_accounts", ["user_id"], "users", ["id"], :name => "twitter_accounts_ibfk_1"

  add_foreign_key "users", ["age_range_id"], "age_ranges", ["id"], :name => "users_ibfk_1"

  add_foreign_key "videos", ["category_id"], "categories", ["id"], :name => "videos_ibfk_1"
  add_foreign_key "videos", ["posted_by_id"], "users", ["id"], :name => "videos_ibfk_2"
  add_foreign_key "videos", ["feed_importer_report_id"], "feed_importer_reports", ["id"], :name => "videos_ibfk_3"

  add_foreign_key "views", ["user_id"], "users", ["id"], :name => "views_ibfk_1"

  add_foreign_key "votes", ["user_id"], "users", ["id"], :name => "votes_ibfk_1"
  add_foreign_key "votes", ["video_id"], "videos", ["id"], :name => "votes_ibfk_2"

  add_foreign_key "words", ["word_list_id"], "word_lists", ["id"], :name => "words_ibfk_1"

  add_foreign_key "you_tube_categories", ["category_id"], "categories", ["id"], :name => "you_tube_categories_ibfk_1"

end
