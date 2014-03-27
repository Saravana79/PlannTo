class Admin::AdReportsController < ApplicationController
  before_filter :authenticate_publisher_user!
  layout "product"

  def index
    @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date]
    @end_date = params[:to_date].blank? ? Time.now : params[:to_date]
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
    @end_date = params[:to_date].blank? ? Time.now : params[:to_date].to_date

    imp_report_results = AddImpression.chart_data(params[:ad_id], @start_date, @end_date)
    @result_array = imp_report_results.map {|result| result.values}
    @x_values = @result_array.map {|each_array| each_array[0]}
    @impressions = @result_array.map {|each_array| each_array[1]}

    click_report_results = Click.chart_data(params[:ad_id], @start_date, @end_date)
    @click_result_array = click_report_results.map {|result| result.values}
    @click_x_values = @click_result_array.map {|each_array| each_array[0]}
    @clicks = @click_result_array.map {|each_array| each_array[1]}
  end
end
