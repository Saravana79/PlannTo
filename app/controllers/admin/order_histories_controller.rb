class Admin::OrderHistoriesController < ApplicationController
 before_filter :authenticate_publisher_user!
 skip_before_filter :authenticate_publisher_user!, :if => proc {|c| current_user && current_user.is_admin?}
 before_filter :authenticate_admin_user!, :only => [:orders]
 layout "product"

  def index
    @search_path = "/admin/impression_reports"

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

  def orders
    params[:search] ||= {}
    @search_path = "/admin/orders"
    # user_relation = UserRelationship.where(:user_id => current_user.id, :relationship_type => "Vendor").first
    # vendor_id = user_relation.blank? ? "" : user_relation.relationship_id
    # @vendor = Vendor.find_by_id(vendor_id)
    # @advertisement = Advertisement.new(:user_id => current_user.id, :vendor_id => vendor_id)
    # @advertisements = [@advertisement]
    @publishers = Publisher.all
    # @vendors =  VendorDetail.all
    @order_history = OrderHistory.new(:no_of_orders => 1)

    condition = "1=1"
    unless params[:search].blank?
      condition = condition + " and vendor_ids = #{params[:search][:vendor_id]}" unless params[:search][:vendor_id].blank?
      condition = condition + " and order_status = '#{params[:search][:order_status]}'" unless params[:search][:order_status].blank?
      condition = condition + " and payment_status = '#{params[:search][:payment_status]}'" unless params[:search][:payment_status].blank?
    end

    if params[:commit] == "Clear"
      condition = "1=1"
      params[:search] = {}
    elsif params[:commit] != "Filter"
      params[:search] ||= {}
    end

    @order_histories = OrderHistory.where(condition).order('order_date desc').paginate(:per_page => 20,:page => params[:page])
    vendor_ids = OrderHistory.select("distinct vendor_ids").map(&:vendor_ids)

    @vendors =  VendorDetail.where(:item_id => vendor_ids)

    # render :layout => false
  end

  def get_item_details
    return_val = {:invalid_id => true}
    impression = AddImpression.where(:id => params[:impression_id].to_s.strip).first
    unless impression.blank?
      item = impression.item
      return_val = { :item_id => item.id, :item_name => item.name, :invalid_id => false, :publisher_id => impression.publisher_id, :hosted_site_url => impression.hosted_site_url, :sid => impression.sid, :advertisement_id => impression.advertisement_id } unless item.blank?
    end
    render :js => return_val.to_json
  end

  def create
    condition = "1=1"
    params[:search] ||= {}
    @publishers = Publisher.all
    @vendors =  VendorDetail.all

    @order_history = OrderHistory.new(params[:order_history])
    @order_histories = OrderHistory.where(condition).order('order_date desc').paginate(:per_page => 20,:page => params[:page])

    if @order_history.save
      p @order_history
      redirect_to admin_orders_path
    else
      render :orders
    end
  end

  def edit
    @publishers = Publisher.all
    @vendors = VendorDetail.all

    @order_history = OrderHistory.where(:id => params[:id]).first
  end

  def update
    @publishers = Publisher.all
    @vendors = VendorDetail.all

    @order_history = OrderHistory.where(:id => params[:id]).first

    if @order_history.update_attributes(params[:order_history])
      redirect_to admin_orders_path
    else
      render "edit"
    end
  end

  def destroy
    @order_history = OrderHistory.where(:id => params[:id]).first

    if @order_history
      @order_history.destroy
    end
    redirect_to admin_orders_path
  end

  def import
    file = params[:file]
    if !file.blank?
      file_new = file.tempfile

      if file.content_type == "text/csv"
        begin
          OrderHistory.update_orders_from_flipkart(file_new.path)
          flash[:notice] = "File Successfully Processed"
        rescue Exception => e
          flash[:alert] = "File not valid"
        end
      else
        flash[:alert] = "File Format Not Supported"
      end
    else
      flash[:alert] = "Please select file"
    end
    redirect_to admin_orders_path
  end
end
