class Admin::OrderHistoriesController < ApplicationController
 before_filter :authenticate_publisher_user!
 layout "product"

  def index
    @impressionscount = 0
    @clickscount = 0
    publisher_id = UserRelationship.where(:relationship_type => "Publisher",:user_id => current_user.id).first.relationship_id
   @publisher = Publisher.find(publisher_id)
   @start_date = params[:from_date].blank? ? 1.week.ago.utc : params[:from_date]
   @end_date = params[:to_date].blank? ? Time.zone.now.utc : params[:to_date]

   # @impressionscount  = AddImpression.where("publisher_id=? and DATE(impression_time) >=? and DATE(impression_time) <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').count
   # @clicks = Click.where("publisher_id=? and DATE(timestamp) >=? and DATE(timestamp) <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').paginate(:per_page => 20,:page => params[:page])
   # @clickscount = @clicks.count
   @total_orders =  OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=?",publisher_id,@start_date.to_date,@end_date.to_date).sum('no_of_orders')
   @total_revenue = OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=?",publisher_id,@start_date.to_date,@end_date.to_date).sum('total_revenue')
   @order_histories = OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=?",publisher_id,@start_date.to_date,@end_date.to_date).order('created_at desc').paginate(:per_page => 20,:page => params[:page])
   @vendors =  VendorDetail.all

    @result = AggregatedDetail.get_counts(@start_date.to_date, @end_date.to_date, publisher_id).first
    unless @result.blank?
      @impressionscount = @result.impressions_count.to_i
      @clickscount = @result.clicks_count.to_i
    end
  end
end
