class Admin::ImpressionReportsController < ApplicationController
 before_filter :authenticate_publisher_user!
 layout "product"
 
 def index
   publisher_id = UserVendor.where(:relationship_type => "Publisher",:user_id => current_user.id).first.relationship_id
   @start_date = params[:from_date].blank? ? 1.month.ago : params[:from_date]
   @end_date = params[:to_date].blank? ? Time.now : params[:to_date]
   @impressions = AddImpression.where("publisher_id=? and impression_time >=? and impression_time <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').paginate(:per_page => 10,:page => params[:page])
   @clicks = Click.where("publisher_id=? and timestamp >=? and timestamp <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').paginate(:per_page => 10,:page => params[:page])
 end
 end
