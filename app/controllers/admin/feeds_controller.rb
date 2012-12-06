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

  def add_vote
     user_ids = configatron.content_creator_user_ids.split(",")
    content = Content.find(params[:id])
    #if content.votes.size == 0
    user_ids.each do |user_id|
    voter = User.find(user_id)      
      unless voter.voted_on? content       
        voter.vote content,:direction => "up"
      end
      end
      content.update_attribute(:total_votes, 5)
     # end
     redirect_to :back
      end
    
end
