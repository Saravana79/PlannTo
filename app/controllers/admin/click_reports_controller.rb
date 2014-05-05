class Admin::ClickReportsController < ApplicationController
  before_filter :authenticate_publisher_user!
  layout "product"
  def index
    publisher_id = UserRelationship.where(:relationship_type => "Publisher",:user_id => current_user.id).first.relationship_id
   @publisher = Publisher.find(publisher_id)
   @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date]
   @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date]

   #@impressions = AddImpression.paginate_by_sql("select impression_time,hosted_site_url,count(*) as count from add_impressions where publisher_id=#{publisher_id} and impression_time >='#{@start_date.to_date}' and  DATE(impression_time)<='#{@end_date.to_date}' group by hosted_site_url order by count(*) desc",:per_page => 20,:page => params[:page])
   @impressionscount  = AddImpression.where("publisher_id=? and DATE(impression_time) >=? and DATE(impression_time) <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').count
  @clicks = Click.where("publisher_id=? and DATE(timestamp) >=? and DATE(timestamp) <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').paginate(:per_page => 20,:page => params[:page])
   @clickscount = @clicks.count
   @total_orders =  OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=?",publisher_id,@start_date.to_date,@end_date.to_date).sum('no_of_orders')
   @total_revenue = OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=?",publisher_id,@start_date.to_date,@end_date.to_date).sum('total_revenue')
  end
end
