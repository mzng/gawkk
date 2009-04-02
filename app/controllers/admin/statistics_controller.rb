class Admin::StatisticsController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def registrations
    @total = User.count(:all, :conditions => {:feed_owner => false})
    
    
    registrations_per_day = User.find(:all, :select => "count(*) as registrations, year(created_at) as year, month(created_at) as month, day(created_at) as day, dayofyear(created_at) as dayofyear", :conditions => ['feed_owner = false and created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, dayofyear', :order => 'created_at')
    registration_counts_per_day = registrations_per_day.collect{|summary| summary.registrations.to_i}
    registration_months_per_day = registrations_per_day.collect{|summary| summary.month + '/' + summary.year}.uniq
    
    @per_day = GChart.line(:data => [registration_counts_per_day], :extras => {'chtt' => 'Per Day', 'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{registration_months_per_day.join('|')}|", 'chxr' => "1,0,#{registration_counts_per_day.max}"})
    
    
    registrations_per_week = User.find(:all, :select => "count(*) as registrations, year(created_at) as year, month(created_at) as month, day(created_at) as day, week(created_at) as week", :conditions => ['feed_owner = false and created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, week', :order => 'created_at')
    registration_counts_per_week = registrations_per_week.collect{|summary| summary.registrations.to_i}
    registration_months_per_week = registrations_per_week.collect{|summary| summary.month + '/' + summary.year}.uniq
    
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
end
