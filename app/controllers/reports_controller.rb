class ReportsController < ApplicationController
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
   @report.report_from_page = request.path
   @report.save
 end

  private

  def find_reportable_object
    if params[:type] == "content" 
      @reportable_object = Content.find(params[:content_id])
    else
      @reportable_object = Comment.find(params[:comment_id])  
  end
  end
end
