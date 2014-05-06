class Admin::OrderHistoriesController < ApplicationController
 before_filter :authenticate_publisher_user!
 layout "product"

  def index

    # condition = "1=1"
    condition = ""
    unless params[:search].blank?
      condition = condition + " and vendor_ids = #{params[:search][:vendor_id]}" unless params[:search][:vendor_id].blank?
      condition = condition + " and order_status = '#{params[:search][:order_status]}'" unless params[:search][:order_status].blank?
      condition = condition + " and payment_status = '#{params[:search][:payment_status]}'" unless params[:search][:payment_status].blank?
    end

    if params[:commit] == "Clear"
      condition = ""
      params[:search] = {}
    elsif params[:commit] != "Filter"
      params[:search] ||= {}
    end

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
   @order_histories = OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=? #{condition}",publisher_id,@start_date.to_date,@end_date.to_date).order('order_date desc').paginate(:per_page => 20,:page => params[:page])

   vendor_ids = OrderHistory.select("distinct vendor_ids").map(&:vendor_ids)

   @vendors =  VendorDetail.where(:item_id => vendor_ids)

    @result = AggregatedDetail.get_counts(@start_date.to_date, @end_date.to_date, publisher_id).first
    unless @result.blank?
      @impressionscount = @result.impressions_count.to_i
      @clickscount = @result.clicks_count.to_i
    end

    # reports graph
    imp_report_results = AggregatedDetail.chart_data_widgets(publisher_id, @start_date.to_date, @end_date.to_date, types=[])
    @result_array = imp_report_results.map {|result| result.values}
    @x_values = @result_array.map {|each_array| each_array[0]}
    @impressions = @result_array.map {|each_array| each_array[1]}
    @clicks = @result_array.map {|each_array| each_array[2]}

  end
end
