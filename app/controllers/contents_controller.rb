class ContentsController < ApplicationController

  layout :false
  def feed
    
    @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
    
    respond_to do |format|
      format.html { render "feed", :locals => {:params => params} }
      format.js { render "feed", :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
    end
  end

  def create
    @content = PlanntoContent.new params[:content]
    @content.field1 = params[:type]
		@content.user = current_user	
    @content.save_with_items!(params[:item_id])
  end

end
