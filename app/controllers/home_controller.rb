class HomeController < ApplicationController
caches_action :index, :unless => :current_user, :cache_path => Proc.new { |c| c.params }
caches_action :terms_conditions, :unless => :current_user, :cache_path => Proc.new { |c| c.params }
caches_action :privacy_policy, :unless => :current_user, :cache_path => Proc.new { |c| c.params }
caches_action :about_us, :unless => :current_user, :cache_path => Proc.new { |c| c.params }

  layout "product"
   def index
     @itemtypes_list =  Itemtype.where("itemtype in (?)", Item::ITEMTYPES-["Manufacturer","Car Group","Topic"])      
    if current_user
      get_objects_for_my_feeds
      render "contents/my_feeds"
    else
      @static_page = "true"
      @static_page1 = "true"
      render :index
    end 
      
   end

  def terms_conditions
    @static_page ="true"
  end
  
  def privacy_policy
   @static_page ="true"
  end
  
  def about_us
    @static_page ="true"
  end
 
 def dialog_test
 
 end
 private
 
 def get_objects_for_my_feeds
     @buying_plan = params[:buying_plan]
     @buying_plans = BuyingPlan.where("user_id = ? and (deleted  IS NULL or deleted = 0)",   current_user.id)
   @items,@item_types,@article_categories,@root_items = Content.follow_items_contents(current_user,params[:item_types],params[:type])
      filter_params = {"sub_type" => @article_categories}
      filter_params["itemtype_id"] = @item_types 
      @follows,@followers = Follow.get_followers_following(current_user,"Followers",1,24)
      @follows,@following = Follow.get_followers_following(current_user,"Following",1,24)
      @follow_items = Item.get_follows_items_for_user(current_user)
      @owned_items = Item.get_owned_items_for_user(current_user)
      @buyer_items = Item.get_buyer_items_for_user(current_user)
      if @items.size > 0 and !@item_types.blank?
        if @items.is_a? Array
            items = @items
        else
          items = @items.split(",")
        end
       filter_params["items_id"] = items
       filter_params["content_ids"] = Content.follow_content_ids(current_user,@article_categories)
       filter_params["status"] = 1
       filter_params["created_by"] = User.get_follow_users_id(current_user)
       filter_params["page"] = 1
       filter_params["root_items"] = @root_items
       filter_params["guide"] = params[:guide] if params[:guide].present?
       filter_params["order"] = "created_at desc"
       @contents = Content.my_feeds_filter(filter_params,current_user)
    end
 end   
 end
 
