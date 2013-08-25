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
   
  def approve
    content = Content.find(params[:id])
    content.update_attribute('status',1)
    ContentAction.create(:action_done_by => current_user.id,:reason => "",:time => Time.now, :sent_mail => false,:content_id => content.id,:action => "approved" )
    if content.is_a?ArticleContent
      if content.url!=nil
         Point.add_point_system(current_user, content, Point::PointReason::CONTENT_SHARE)
      else
        Point.add_point_system(current_user, content, Point::PointReason::CONTENT_CREATE) 
      end
    else
      Point.add_point_system(current_user, content, Point::PointReason::CONTENT_CREATE) 
    end      
          
    redirect_to :back  
  end
  
  def reject
    @content = Content.find(params[:id])
    @content.update_attribute('status',Content::REJECTED)
    @content.remove_user_activities
  end
  
  def content_action
    @content = Content.find(params[:id])
    @detail = params[:detail]
    if @content.rejected?
        ContentAction.create(:action_done_by => current_user.id,:reason =>  params[:content_action][:reason],:time => Time.now, :sent_mail => params[:content_action][:sent_mail],:content_id => @content.id,:action => "rejected" )
   elsif @content.deleted?
       ContentAction.create(:action_done_by => current_user.id,:reason =>  params[:content_action][:reason],:time => Time.now, :sent_mail => params[:content_action][:sent_mail],:content_id => @content.id,:action => "deleted" )
   end 
   if params[:content_action][:sent_mail] == "1"
     ContentMailer.content_action(@content,params[:content_action][:reason]).deliver 
   end
   if @detail == "true"
     @itemtype = @content.items.first.get_base_itemtype 
   end       
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
