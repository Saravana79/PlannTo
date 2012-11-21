class Admin::FeedsController < ApplicationController
  layout "product"
   before_filter :authenticate_admin_user!
  def index
    @items,@item_types,@article_categories,@root_items = Content.follow_items_contents(current_user,params[:item_types],params[:type])
      filter_params = {"sub_type" => @article_categories}
      filter_params["itemtype_id"] = @item_types 
      filter_params["items_id"] = ""
      filter_params["status"] = 1
      filter_params["created_by"] = User.find(:all).collect(&:id)
      filter_params["page"] = 1
      filter_params["guide"] = params[:guide] if params[:guide].present?
      filter_params["order"] = "created_at desc"
      @contents = Content.my_feeds_filter(filter_params,current_user)
    end

end
