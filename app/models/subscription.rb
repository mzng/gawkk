class Subscription < ActiveRecord::Base
  belongs_to :user
  belongs_to :channel, :counter_cache => true
end
