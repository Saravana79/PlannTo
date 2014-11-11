class Admin::AdReportsController < ApplicationController
  before_filter :authenticate_admin_user!, :except => [:view_ad_chart, :report]
  before_filter :authenticate_user!, :only => [:view_ad_chart, :report]
  layout "product"

  def index
    @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date]
    @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date]
    # reports by advertisements
    @advertisements = Advertisement.all
    click_report = Click.find_by_sql("select count(*) as clicks_count, ad.id from clicks c join add_impressions i on c.impression_id=i.id join advertisements ad
                                     on i.advertisement_id=ad.id where i.impression_time >='#{@start_date.to_date}' and  DATE(i.impression_time)<='#{@end_date.to_date}'
                                     group by ad.id")
    @click_report = {}
    @click_report.default = 0

    click_report.each {|each_click| @click_report.merge!("#{each_click.id}" => "#{each_click.clicks_count}")}

    impression_report = AddImpression.find_by_sql("select count(*) as impressions_count, ad.id from add_impressions i join advertisements ad on i.advertisement_id=ad.id where
                                                  i.impression_time >='#{@start_date.to_date}' and  DATE(i.impression_time)<='#{@end_date.to_date}'
                                                  group by ad.id")
    @impression_report = {}
    @impression_report.default = 0

    impression_report.each {|each_impression| @impression_report.merge!("#{each_impression.id}" => "#{each_impression.impressions_count}")}
  end

  def view_chart
    @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date].to_date
    @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date].to_date

    imp_report_results = AddImpression.chart_data(params[:ad_id], @start_date, @end_date)
    @result_array = imp_report_results.map {|result| result.values}
    @x_values = @result_array.map {|each_array| each_array[0]}
    @impressions = @result_array.map {|each_array| each_array[1]}

    click_report_results = Click.chart_data(params[:ad_id], @start_date, @end_date)
    @click_result_array = click_report_results.map {|result| result.values}
    @click_x_values = @click_result_array.map {|each_array| each_array[0]}
    @clicks = @click_result_array.map {|each_array| each_array[1]}
  end

  def widget_reports
    @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date].to_date
    @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date].to_date
    @search_path = admin_widget_reports_path

    @publishers = Publisher.all
    params[:publisher_id] ||= Publisher.first.id

    @publisher = Publisher.find_by_id(params[:publisher_id])
    @vendors = Vendor.all

    params[:vendor_id] ||= nil

    types = []
    # ad_types = AddImpression.select("distinct advertisement_type").map(&:advertisement_type)
    # types = ad_types - ['advertisement']

    # imp_report_results = AddImpression.chart_data_widgets(params[:publisher_id], @start_date, @end_date, types)   #TODO: have to remove method definition also
    imp_report_results = AggregatedDetail.chart_data_widgets(params[:publisher_id], @start_date, @end_date, types)
    @result_array = imp_report_results.map {|result| result.values}
    @x_values = @result_array.map {|each_array| each_array[0]}
    @impressions = @result_array.map {|each_array| each_array[1]}
    @clicks = @result_array.map {|each_array| each_array[2]}
    @winning_price = @result_array.map {|each_array| ("%.2f" % each_array[3].to_f).to_f}

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

    @order_histories = OrderHistory.where("publisher_id=? and DATE(order_date) >=? and DATE(order_date) <=? #{condition}", @publisher.id,@start_date.to_date,@end_date.to_date).order('order_date desc').paginate(:per_page => 20,:page => params[:page])
    vendor_ids = OrderHistory.select("distinct vendor_ids").map(&:vendor_ids)

    @impressionscount = @impressions.sum
    @clickscount = @clicks.sum
    @total_orders = @order_histories.count
    @total_revenue = @order_histories.map(&:total_revenue).compact.inject(:+) rescue 0

    @vendors =  VendorDetail.where(:item_id => vendor_ids)

    # click_report_results = AggregatedDetail.chart_data_widgets_for_click(params[:publisher_id], @start_date, @end_date, types, params[:vendor_id])
    # @click_result_array = imp_report_results.map {|result| result.values}
    # @click_x_values = @click_result_array.map {|each_array| each_array[0]}
    # @clicks = @click_result_array.map {|each_array| each_array[2]}
  end

  def load_vendors
    @publisher = Publisher.find_by_id(params[:publisher_id])
    @vendors = Vendor.all
    render :partial => "vendor_details", :object => @vendors
  end

  def view_ad_chart
    @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date].to_date
    @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date].to_date
    @search_path = admin_ad_report_view_ad_chart_path
    @advertisement = Advertisement.where(:id => params[:advertisement_id]).first

    @publishers = Publisher.all
    params[:publisher_id] ||= Publisher.first.id

    @publisher = Publisher.find_by_id(params[:publisher_id])
    @vendors = Vendor.all

    params[:vendor_id] ||= nil

    types = []

    imp_report_results = AggregatedDetail.chart_data_for_ad(params[:advertisement_id], @start_date, @end_date, types)

    @result_array = imp_report_results.map {|result| result.values}
    @x_values = @result_array.map {|each_array| each_array[0]}
    @impressions = @result_array.map {|each_array| each_array[1]}
    @clicks = @result_array.map {|each_array| each_array[2]}
    @winning_price = @result_array.map {|each_array| ("%.2f" % each_array[3].to_f).to_f}
    @winning_price = @winning_price.map {|each_win| @advertisement.commission.blank? ? each_win : each_win+each_win/@advertisement.commission.to_f/100}



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

    @order_histories = OrderHistory.where("advertisement_id=? and DATE(order_date) >=? and DATE(order_date) <=? #{condition}", @advertisement.id,@start_date.to_date,@end_date.to_date).order('order_date desc').paginate(:per_page => 20,:page => params[:page])
    @impressionscount = @impressions.sum
    @clickscount = @clicks.sum

    @total_ectr = 0.0

    if (@clickscount != 0.0 && @impressionscount != 0.0)
      @total_ectr = (@clickscount.to_f / @impressionscount.to_f) rescue 0.0
    end

    @total_ectr = @total_ectr * 100

    # @total_orders = @order_histories.count
    # @total_revenue = @order_histories.map(&:total_revenue).compact.inject(:+) rescue 0
    @total_cost = @winning_price.compact.inject(:+) rescue 0.0

    @cost_per_click = 0.0

    if (@total_cost != 0.0 && @clickscount != 0.0)
      @cost_per_click = (@total_cost.to_f / @clickscount.to_f) rescue 0.0
    end

    vendor_ids = OrderHistory.select("distinct vendor_ids").map(&:vendor_ids)

    @vendors =  VendorDetail.where(:item_id => vendor_ids)
  end

  def report
    params[:select_by] ||= "hosted_site_url"
    @start_date = params[:from_date] = params[:from_date].blank? ? Date.today : params[:from_date].to_date
    @end_date = params[:to_date] = params[:to_date].blank? ? Date.today : params[:to_date].to_date
    user_condition = current_user.is_admin? ? "1=1" : "user_id = #{current_user.id}"
    advertisement = Advertisement.find_by_sql("select * from advertisements where id = #{params[:id]} and #{user_condition}").last
    if !advertisement.blank?
      export = request.format == "text/csv" ? true : false
      @reports = advertisement.get_reports(params, export)
    end

    respond_to do |format|
      format.html
      format.csv {
        date = params[:from_date].to_date.strftime("%b_%d") + "_to_" + params[:to_date].to_date.strftime("%b_%d")
        response.headers['Content-Disposition'] = 'attachment; filename="ad_report_' + date + '_' + params[:id] + '.csv"'
        render :text => Advertisement.to_csv(params, @reports)
      }
    end
  end
end
