class HomeController < ApplicationController
  layout "product"
  def index
    if current_user
      get_objects_for_my_feeds
      render "contents/my_feeds"
    else
      render :index
    end     
   end
  
  def terms_conditions
  
  end
  
  def privacy_policy
  
  end
  
  def about_us
  
  end
 
 
 private
 
 def get_objects_for_my_feeds
   @items,@item_types,@article_categories,@root_items = Content.follow_items_contents(current_user,params[:item_types],params[:type])
      filter_params = {"sub_type" => @article_categories}
      filter_params["itemtype_id"] = @item_types 
    
      if @items.size > 0 and !@item_types.blank?
        if @tems.is_a? Array
            items = @items
        else
          items = @items.split(",")
        end
       filter_params["items_id"] = items
       filter_params["status"] = 1
       filter_params["created_by"] = User.get_follow_users_id(current_user)
       filter_params["page"] = 1
       filter_params["root_items"] = @root_items
       filter_params["guide"] = params[:guide] if params[:guide].present?
       filter_params["order"] = "created_at desc"
       @contents = Content.my_feeds_filter(filter_params)
    end
 end   
 end
 
