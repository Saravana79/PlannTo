class ContentsController < ApplicationController
  before_filter :authenticate_user!, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  before_filter :get_item_object, :only => [:follow_this_item, :own_a_item, :plan_to_buy_item, :follow_item_type]
  layout :false
  include FollowMethods
  def feed
    
    @contents = Content.filter(params.slice(:items, :type, :order, :limit, :page))
    
    respond_to do |format|
      format.html { render "feed", :locals => {:params => params} }
      format.js { render "feed", :locals => {:contents_string => render_to_string(:partial => "contents", :locals => {:params => params}) }}
    end
  end

  def show
    @content = Content.find(params[:id])
    @comment = Comment.new
    render :layout => "product"
  end

  def create
    @content = PlanntoContent.new params[:content]
    @content.field1 = params[:type]
		@content.user = current_user	
    @content.save_with_items!(params[:item_id])
  end

  private
  def get_item_object
    @item = Content.find(params[:id])
  end

end
