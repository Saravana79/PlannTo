class ReportsController < ApplicationController
 before_filter :authenticate_user!
 before_filter :find_reportable_object
 
 def index
 
 end
 
 def new
   @report = Report.new
   @type = params[:type]
  end

 def create
   @report = @reportable_object.reports.create(params[:report])
   @report.reported_by = current_user.id
   @report.report_from_page = session[:return_to]
   @report.save
 end

 def article_reports
   @start_date = params[:from_date].blank? ? 1.week.ago : params[:from_date].to_date
   @end_date = params[:to_date].blank? ? Time.zone.now : params[:to_date].to_date

   @results = ArticleContent.reports_from_article_content(@start_date, @end_date)

   render :layout => "product"
 end

  private

  def find_reportable_object
    if params[:type] == "content" 
      @reportable_object = Content.find(params[:content_id])
    elsif params[:type] == "comment"
      @reportable_object = Comment.find(params[:comment_id]) 
    elsif params[:type] == "dealer"
      @reportable_object = Item.find(params[:item_id])
   end
  end
end
