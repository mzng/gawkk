class Admin::StatisticsController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def index
    
  end
  
  def comments
    @total = Comment.count(:all)
    @total_today = Comment.count(:all, :conditions => ['date(created_at) = curdate()'])
    
    comments_per_day = Comment.find(:all, :select => "count(*) as comments, year(created_at) as year, month(created_at) as month, day(created_at) as day, dayofyear(created_at) as dayofyear", :conditions => ['created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, dayofyear', :order => 'created_at')
    comment_counts_per_day = comments_per_day.collect{|summary| summary.comments.to_i}
    comment_months_per_day = blank_duplicate_recurring_months(comments_per_day.collect{|summary| summary.month + '/' + summary.year})
    
    @per_day = GChart.line(:data => [comment_counts_per_day], :extras => {'chtt' => 'Per Day', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{comment_months_per_day.join('|')}|", 'chxr' => "1,0,#{comment_counts_per_day.max}"})
    
    
    comments_per_week = Comment.find(:all, :select => "count(*) as comments, year(created_at) as year, month(created_at) as month, day(created_at) as day, week(created_at) as week", :conditions => ['created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, week', :order => 'created_at')
    comment_counts_per_week = comments_per_week.collect{|summary| summary.comments.to_i}
    comment_months_per_week = blank_duplicate_recurring_months(comments_per_week.collect{|summary| summary.month + '/' + summary.year})
    
    @per_week = GChart.line(:data => [comment_counts_per_week], :extras => {'chtt' => 'Per Week', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{comment_months_per_week.join('|')}|", 'chxr' => "1,0,#{comment_counts_per_week.max}"})
  end
  
  def likes
    @total = Like.count(:all)
    @total_today = Like.count(:all, :conditions => ['date(created_at) = curdate()'])
    
    likes_per_day = Like.find(:all, :select => "count(*) as likes, year(created_at) as year, month(created_at) as month, day(created_at) as day, dayofyear(created_at) as dayofyear", :conditions => ['created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, dayofyear', :order => 'created_at')
    like_counts_per_day = likes_per_day.collect{|summary| summary.likes.to_i}
    like_months_per_day = blank_duplicate_recurring_months(likes_per_day.collect{|summary| summary.month + '/' + summary.year})
    
    @per_day = GChart.line(:data => [like_counts_per_day], :extras => {'chtt' => 'Per Day', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{like_months_per_day.join('|')}|", 'chxr' => "1,0,#{like_counts_per_day.max}"})
    
    
    likes_per_week = Like.find(:all, :select => "count(*) as likes, year(created_at) as year, month(created_at) as month, day(created_at) as day, week(created_at) as week", :conditions => ['created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, week', :order => 'created_at')
    like_counts_per_week = likes_per_week.collect{|summary| summary.likes.to_i}
    like_months_per_week = blank_duplicate_recurring_months(likes_per_week.collect{|summary| summary.month + '/' + summary.year})
    
    @per_week = GChart.line(:data => [like_counts_per_week], :extras => {'chtt' => 'Per Week', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{like_months_per_week.join('|')}|", 'chxr' => "1,0,#{like_counts_per_week.max}"})
  end
  
  def registrations
    @total = User.count(:all, :conditions => {:feed_owner => false})
    @total_today = User.count(:all, :conditions => ['feed_owner = false AND date(created_at) = curdate()'])
    
    registrations_per_day = User.find(:all, :select => "count(*) as registrations, year(created_at) as year, month(created_at) as month, day(created_at) as day, dayofyear(created_at) as dayofyear", :conditions => ['feed_owner = false and created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, dayofyear', :order => 'created_at')
    registration_counts_per_day = registrations_per_day.collect{|summary| summary.registrations.to_i}
    registration_months_per_day = blank_duplicate_recurring_months(registrations_per_day.collect{|summary| summary.month + '/' + summary.year})
    
    @per_day = GChart.line(:data => [registration_counts_per_day], :extras => {'chtt' => 'Per Day', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{registration_months_per_day.join('|')}|", 'chxr' => "1,0,#{registration_counts_per_day.max}"})
    
    
    registrations_per_week = User.find(:all, :select => "count(*) as registrations, year(created_at) as year, month(created_at) as month, day(created_at) as day, week(created_at) as week", :conditions => ['feed_owner = false and created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, week', :order => 'created_at')
    registration_counts_per_week = registrations_per_week.collect{|summary| summary.registrations.to_i}
    registration_months_per_week = blank_duplicate_recurring_months(registrations_per_week.collect{|summary| summary.month + '/' + summary.year})
    
    @per_week = GChart.line(:data => [registration_counts_per_week], :extras => {'chtt' => 'Per Week', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{registration_months_per_week.join('|')}|", 'chxr' => "1,0,#{registration_counts_per_week.max}"})
  end
  
  
  private
  def ensure_user_can_administer
    if user_can_administer?
      yield
    else
      redirect_to '/'
    end
  end
  
  def blank_duplicate_recurring_months(months)
    last = ''
    months.each_with_index do |month, i|
      if month == last
        months[i] = ''
      else
        last = month
      end
    end
    
    return months
  end
end
