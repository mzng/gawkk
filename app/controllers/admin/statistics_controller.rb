class Admin::StatisticsController < ApplicationController
  around_filter :ensure_user_can_administer
  layout 'page'
  
  
  def registrations
    @total = User.count(:all, :conditions => {:feed_owner => false})
    
    registrations_per_day = User.find(:all, :select => "count(*) as registrations, year(created_at) as year, month(created_at) as month, dayofyear(created_at) as dayofyear", :conditions => ['feed_owner = false and created_at > date_sub(curdate(), interval 6 month)'], :group => 'year, dayofyear', :order => 'created_at')
    registration_counts = registrations_per_day.collect{|summary| summary.registrations.to_i}
    registration_months = registrations_per_day.collect{|summary| summary.month + '/' + summary.year}.uniq
    
    @chart = GChart.line(:data => [registration_counts], :extras => {'chs' => '900x300', 'chxt' => 'x,y', 'chxl' => "0:|#{registration_months.join('|')}|", 'chxr' => "1,0,#{registration_counts.max}"})
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
